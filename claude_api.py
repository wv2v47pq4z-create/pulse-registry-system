"""
Claude API integration for research paper categorization.
"""
import json
import os
from typing import Dict, Any, Optional
import requests
from models import PaperCategorizationResponse, PaperInput


def build_claude_prompt(paper: PaperInput) -> str:
    """
    Build the master prompt for Claude API based on paper data.
    
    Args:
        paper: PaperInput object containing paper metadata
        
    Returns:
        Formatted prompt string for Claude
    """
    prompt = f"""You are an expert research analyst specializing in technology, blockchain, and AI systems. 
Your task is to analyze the following research paper and provide a structured categorization.

**Paper Details:**
- Title: {paper.title}
- Year: {paper.year if paper.year else "Not specified"}
- Authors: {paper.authors if paper.authors else "Not specified"}
- Abstract: {paper.abstract if paper.abstract else "Not specified"}

**Your Task:**
Analyze this paper and provide a structured JSON response with the following fields:

1. **category**: Choose ONE from: "Core Technology", "Use Case", "Market Research", "Regulatory", "Competitive Analysis", "Other"
2. **priority**: Choose ONE from: "High", "Medium", "Low" (based on relevance and potential impact)
3. **relevance_score**: Rate from 0-10 how relevant this is to blockchain/AI systems
4. **potential_impact**: Brief description (10-500 chars) of potential impact
5. **key_idea**: Main idea or insight from the paper (10-1000 chars)
6. **technical_approach**: Technical approach or methodology (10-1000 chars)
7. **implementation_notes**: Notes on implementation possibilities (10-1000 chars)
8. **related_technologies**: Comma-separated list of related technologies
9. **actionable_insights**: Specific actionable insights or next steps (10-1000 chars)
10. **confidence_level**: Choose ONE from: "High", "Medium", "Low" (your confidence in this categorization)
11. **summary**: Comprehensive summary of the paper (20-2000 chars)

Respond ONLY with valid JSON matching this exact structure. Do not include any markdown formatting or code blocks."""

    return prompt


def call_claude_api(
    paper: PaperInput,
    api_key: Optional[str] = None,
    model: str = "claude-3-5-sonnet-20241022",
    max_tokens: int = 4000
) -> Dict[str, Any]:
    """
    Call Claude API to categorize a research paper.
    
    Args:
        paper: PaperInput object containing paper metadata
        api_key: Claude API key (defaults to CLAUDE_API_KEY env var)
        model: Claude model to use
        max_tokens: Maximum tokens in response
        
    Returns:
        Dictionary containing the validated categorization response and raw JSON
        
    Raises:
        ValueError: If API key is missing or API response is invalid
        requests.RequestException: If API call fails
    """
    # Get API key from parameter or environment
    api_key = api_key or os.getenv("CLAUDE_API_KEY")
    if not api_key:
        raise ValueError("CLAUDE_API_KEY is required but not provided")
    
    # Build the prompt
    prompt = build_claude_prompt(paper)
    
    # Prepare API request
    headers = {
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json"
    }
    
    payload = {
        "model": model,
        "max_tokens": max_tokens,
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ]
    }
    
    # Make API call with robust error handling
    try:
        response = requests.post(
            "https://api.anthropic.com/v1/messages",
            headers=headers,
            json=payload,
            timeout=60
        )
        response.raise_for_status()
        
    except requests.exceptions.Timeout:
        raise requests.RequestException("Claude API request timed out after 60 seconds")
    except requests.exceptions.ConnectionError as e:
        raise requests.RequestException(f"Failed to connect to Claude API: {str(e)}")
    except requests.exceptions.HTTPError as e:
        error_detail = ""
        try:
            error_detail = response.json().get("error", {}).get("message", "")
        except:
            pass
        raise requests.RequestException(
            f"Claude API returned error status {response.status_code}: {error_detail or str(e)}"
        )
    
    # Parse response
    try:
        response_data = response.json()
        content = response_data.get("content", [])
        
        if not content or not isinstance(content, list):
            raise ValueError("Invalid response structure from Claude API")
        
        # Extract text content
        text_content = None
        for item in content:
            if item.get("type") == "text":
                text_content = item.get("text", "")
                break
        
        if not text_content:
            raise ValueError("No text content found in Claude API response")
        
        # Parse JSON from text content
        # Handle potential markdown code blocks
        text_content = text_content.strip()
        if text_content.startswith("```json"):
            text_content = text_content[7:]
        if text_content.startswith("```"):
            text_content = text_content[3:]
        if text_content.endswith("```"):
            text_content = text_content[:-3]
        text_content = text_content.strip()
        
        categorization_data = json.loads(text_content)
        
    except json.JSONDecodeError as e:
        raise ValueError(f"Failed to parse JSON from Claude response: {str(e)}")
    except (KeyError, IndexError) as e:
        raise ValueError(f"Unexpected response structure from Claude API: {str(e)}") from e
    
    # Validate using Pydantic model
    try:
        validated_response = PaperCategorizationResponse(**categorization_data)
    except Exception as e:
        raise ValueError(f"Claude response failed validation: {str(e)}") from e
    
    # Return both validated model and raw JSON string for storage
    return {
        "validated": validated_response,
        "raw_json": json.dumps(categorization_data, indent=2)
    }
