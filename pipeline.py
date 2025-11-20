"""
Core autonomous research pipeline for fetching, categorizing, and storing research papers.
"""
import os
import json
import logging
from typing import List, Dict, Any, Optional
import requests
from pyairtable import Api
from models import PaperInput
from claude_api import call_claude_api


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def fetch_papers_from_elicit(data_url: str) -> List[Dict[str, Any]]:
    """
    Fetch research papers from Elicit data source.
    
    Args:
        data_url: URL to fetch paper data (CSV or JSON format)
        
    Returns:
        List of paper dictionaries
        
    Raises:
        requests.RequestException: If fetching fails
    """
    try:
        response = requests.get(data_url, timeout=30)
        response.raise_for_status()
        
        # Try to parse as JSON first
        try:
            papers = response.json()
            if isinstance(papers, list):
                return papers
            elif isinstance(papers, dict):
                # Might be wrapped in a data key
                return papers.get('data', papers.get('papers', [papers]))
        except json.JSONDecodeError:
            # If not JSON, try CSV parsing
            import csv
            from io import StringIO
            
            csv_data = StringIO(response.text)
            reader = csv.DictReader(csv_data)
            papers = list(reader)
            return papers
            
    except requests.exceptions.RequestException as e:
        logger.error(f"Failed to fetch papers from {data_url}: {str(e)}")
        raise


def check_duplicate_in_airtable(
    table,
    title: str,
    year: Optional[int] = None,
    elicit_id: Optional[str] = None
) -> Optional[Dict[str, Any]]:
    """
    Check if a paper already exists in Airtable.
    Prioritizes matching on Elicit ID, falls back to Title and Year.
    
    Args:
        table: Airtable table object
        title: Paper title
        year: Paper year
        elicit_id: Elicit unique identifier
        
    Returns:
        Existing record if found, None otherwise
    """
    try:
        # First, try to match on Elicit ID if available
        if elicit_id:
            formula = f"{{Elicit ID}} = '{elicit_id}'"
            records = table.all(formula=formula)
            if records:
                logger.info(f"Found existing record by Elicit ID: {elicit_id}")
                return records[0]
        
        # Fall back to Title and Year matching
        if year:
            formula = f"AND({{Title}} = '{title}', {{Year}} = {year})"
        else:
            formula = f"{{Title}} = '{title}'"
        
        records = table.all(formula=formula)
        if records:
            logger.info(f"Found existing record by Title/Year: {title}")
            return records[0]
            
        return None
        
    except Exception as e:
        logger.error(f"Error checking for duplicate: {str(e)}")
        # Continue processing even if duplicate check fails
        return None


def update_airtable_record(
    table,
    paper: PaperInput,
    claude_response: Dict[str, Any],
    processing_status: str = "Completed"
) -> Dict[str, Any]:
    """
    Create or update an Airtable record with paper and categorization data.
    
    Args:
        table: Airtable table object
        paper: PaperInput object
        claude_response: Response from Claude API containing validated data and raw JSON
        processing_status: Status to set for the record
        
    Returns:
        Created or updated Airtable record
    """
    validated = claude_response["validated"]
    
    # Prepare fields for Airtable
    fields = {
        "Title": paper.title,
        "Year": paper.year if paper.year else 0,
        "Elicit ID": paper.elicit_id if paper.elicit_id else "",
        "AI_Raw_JSON": claude_response["raw_json"],
        "Category": validated.category,
        "Priority": validated.priority,
        "Relevance": validated.relevance_score,
        "Potential": validated.potential_impact,
        "Key Idea": validated.key_idea,
        "Technical Approach": validated.technical_approach,
        "Implementation Notes": validated.implementation_notes,
        "Related Technologies": validated.related_technologies,
        "Actionable Insights": validated.actionable_insights,
        "Confidence Level": validated.confidence_level,
        "Summary": validated.summary,
        "Processing Status": processing_status
    }
    
    # Add optional fields if available
    if paper.authors:
        fields["Authors"] = paper.authors
    if paper.abstract:
        fields["Abstract"] = paper.abstract
    if paper.url:
        fields["URL"] = paper.url
    
    try:
        # Check for existing record
        existing = check_duplicate_in_airtable(
            table,
            paper.title,
            paper.year,
            paper.elicit_id
        )
        
        if existing:
            # Update existing record
            record_id = existing["id"]
            logger.info(f"Updating existing record: {record_id}")
            updated = table.update(record_id, fields)
            return updated
        else:
            # Create new record
            logger.info(f"Creating new record for: {paper.title}")
            created = table.create(fields)
            return created
            
    except Exception as e:
        logger.error(f"Error updating Airtable: {str(e)}")
        raise


def process_single_paper(
    table,
    paper_data: Dict[str, Any],
    claude_api_key: str
) -> Dict[str, Any]:
    """
    Process a single paper through the pipeline.
    
    Args:
        table: Airtable table object
        paper_data: Raw paper data dictionary
        claude_api_key: Claude API key
        
    Returns:
        Processing result dictionary
    """
    try:
        # Validate input data
        paper = PaperInput(
            title=paper_data.get("title", paper_data.get("Title", "")),
            year=paper_data.get("year", paper_data.get("Year")),
            abstract=paper_data.get("abstract", paper_data.get("Abstract")),
            elicit_id=paper_data.get("elicit_id", paper_data.get("Elicit ID")),
            authors=paper_data.get("authors", paper_data.get("Authors")),
            url=paper_data.get("url", paper_data.get("URL"))
        )
        
        # Check for duplicate before calling Claude API
        existing = check_duplicate_in_airtable(
            table,
            paper.title,
            paper.year,
            paper.elicit_id
        )
        
        if existing:
            logger.info(f"Skipping duplicate paper: {paper.title}")
            return {
                "status": "skipped",
                "reason": "duplicate",
                "paper": paper.title
            }
        
        # Call Claude API for categorization
        logger.info(f"Categorizing paper with Claude API: {paper.title}")
        claude_response = call_claude_api(paper, api_key=claude_api_key)
        
        # Update Airtable with results
        record = update_airtable_record(table, paper, claude_response)
        
        return {
            "status": "success",
            "paper": paper.title,
            "record_id": record["id"]
        }
        
    except Exception as e:
        logger.error(f"Error processing paper: {str(e)}")
        
        # Try to update Airtable with failure status
        try:
            fields = {
                "Title": paper_data.get("title", paper_data.get("Title", "Unknown")),
                "Processing Status": "Failed",
                "Failure_Reason": str(e)
            }
            if paper_data.get("year") or paper_data.get("Year"):
                fields["Year"] = paper_data.get("year", paper_data.get("Year"))
            if paper_data.get("elicit_id") or paper_data.get("Elicit ID"):
                fields["Elicit ID"] = paper_data.get("elicit_id", paper_data.get("Elicit ID"))
            
            table.create(fields)
        except:
            pass  # If we can't even create a failure record, just log it
        
        return {
            "status": "failed",
            "paper": paper_data.get("title", "Unknown"),
            "error": str(e)
        }


def run_autonomous_pipeline(
    airtable_api_key: Optional[str] = None,
    airtable_base_id: Optional[str] = None,
    airtable_table_name: Optional[str] = None,
    claude_api_key: Optional[str] = None,
    elicit_data_url: Optional[str] = None
) -> Dict[str, Any]:
    """
    Main pipeline function that orchestrates the entire autonomous research pipeline.
    
    This function is idempotent - it can be run multiple times safely with duplicate detection.
    
    Args:
        airtable_api_key: Airtable API key (defaults to AIRTABLE_API_KEY env var)
        airtable_base_id: Airtable base ID (defaults to AIRTABLE_BASE_ID env var)
        airtable_table_name: Airtable table name (defaults to AIRTABLE_TABLE_NAME env var)
        claude_api_key: Claude API key (defaults to CLAUDE_API_KEY env var)
        elicit_data_url: URL for fetching paper data (defaults to ELICIT_DATA_URL env var)
        
    Returns:
        Dictionary with pipeline execution results and statistics
        
    Raises:
        ValueError: If required environment variables are missing
    """
    # Load configuration from environment or parameters
    airtable_api_key = airtable_api_key or os.getenv("AIRTABLE_API_KEY")
    airtable_base_id = airtable_base_id or os.getenv("AIRTABLE_BASE_ID")
    airtable_table_name = airtable_table_name or os.getenv("AIRTABLE_TABLE_NAME", "Pulse Systems Research")
    claude_api_key = claude_api_key or os.getenv("CLAUDE_API_KEY")
    elicit_data_url = elicit_data_url or os.getenv("ELICIT_DATA_URL")
    
    # Validate required parameters
    missing_params = []
    if not airtable_api_key:
        missing_params.append("AIRTABLE_API_KEY")
    if not airtable_base_id:
        missing_params.append("AIRTABLE_BASE_ID")
    if not claude_api_key:
        missing_params.append("CLAUDE_API_KEY")
    if not elicit_data_url:
        missing_params.append("ELICIT_DATA_URL")
    
    if missing_params:
        raise ValueError(f"Missing required environment variables: {', '.join(missing_params)}")
    
    logger.info("Starting autonomous research pipeline")
    logger.info(f"Target Airtable: {airtable_base_id}/{airtable_table_name}")
    
    try:
        # Initialize Airtable connection
        api = Api(airtable_api_key)
        table = api.table(airtable_base_id, airtable_table_name)
        
        # Fetch papers from Elicit
        logger.info(f"Fetching papers from: {elicit_data_url}")
        papers = fetch_papers_from_elicit(elicit_data_url)
        logger.info(f"Fetched {len(papers)} papers")
        
        # Process each paper
        results = []
        for i, paper_data in enumerate(papers, 1):
            logger.info(f"Processing paper {i}/{len(papers)}")
            result = process_single_paper(table, paper_data, claude_api_key)
            results.append(result)
        
        # Calculate statistics
        stats = {
            "total": len(results),
            "success": sum(1 for r in results if r["status"] == "success"),
            "skipped": sum(1 for r in results if r["status"] == "skipped"),
            "failed": sum(1 for r in results if r["status"] == "failed")
        }
        
        logger.info(f"Pipeline completed: {stats}")
        
        return {
            "status": "completed",
            "statistics": stats,
            "results": results
        }
        
    except Exception as e:
        logger.error(f"Pipeline failed: {str(e)}")
        return {
            "status": "failed",
            "error": str(e)
        }
