"""
Main entry point for the Autonomous Research Pipeline.
"""
import os
import sys
import json
import argparse
from pathlib import Path
from dotenv import load_dotenv
from pipeline import run_autonomous_pipeline


def load_environment():
    """
    Load environment variables from .env file if it exists.
    """
    env_file = Path(__file__).parent / ".env"
    if env_file.exists():
        load_dotenv(env_file)
        print(f"Loaded environment variables from {env_file}")
    else:
        print("No .env file found, using system environment variables")


def validate_environment():
    """
    Validate that all required environment variables are set.
    
    Returns:
        Tuple of (is_valid, missing_vars)
    """
    required_vars = [
        "AIRTABLE_API_KEY",
        "AIRTABLE_BASE_ID",
        "CLAUDE_API_KEY",
        "ELICIT_DATA_URL"
    ]
    
    missing_vars = [var for var in required_vars if not os.getenv(var)]
    
    return len(missing_vars) == 0, missing_vars


def main():
    """
    Main function to execute the autonomous research pipeline.
    """
    parser = argparse.ArgumentParser(
        description="Autonomous Research Pipeline - Fetch, categorize, and store research papers"
    )
    parser.add_argument(
        "--validate-only",
        action="store_true",
        help="Only validate environment variables without running the pipeline"
    )
    parser.add_argument(
        "--output",
        type=str,
        help="Output results to a JSON file"
    )
    
    args = parser.parse_args()
    
    print("=" * 80)
    print("Autonomous Research Pipeline")
    print("=" * 80)
    print()
    
    # Load environment variables
    load_environment()
    
    # Validate environment
    is_valid, missing_vars = validate_environment()
    
    if not is_valid:
        print("❌ ERROR: Missing required environment variables:")
        for var in missing_vars:
            print(f"  - {var}")
        print()
        print("Please set these variables in your environment or create a .env file.")
        print("See .env.example for reference.")
        sys.exit(1)
    
    print("✅ Environment validation passed")
    print()
    
    if args.validate_only:
        print("Validation complete. Exiting.")
        sys.exit(0)
    
    # Display configuration (without showing sensitive values)
    print("Configuration:")
    print(f"  Airtable Base ID: {os.getenv('AIRTABLE_BASE_ID')}")
    print(f"  Airtable Table: {os.getenv('AIRTABLE_TABLE_NAME', 'Pulse Systems Research')}")
    print(f"  Data Source: {os.getenv('ELICIT_DATA_URL')}")
    print(f"  Claude API Key: {'*' * 20}{os.getenv('CLAUDE_API_KEY', '')[-4:]}")
    print()
    
    # Run the pipeline
    print("Starting pipeline execution...")
    print("-" * 80)
    print()
    
    try:
        result = run_autonomous_pipeline()
        
        print()
        print("-" * 80)
        print("Pipeline Execution Complete")
        print("-" * 80)
        
        if result["status"] == "completed":
            stats = result["statistics"]
            print(f"✅ Pipeline completed successfully")
            print()
            print("Statistics:")
            print(f"  Total papers processed: {stats['total']}")
            print(f"  Successfully categorized: {stats['success']}")
            print(f"  Skipped (duplicates): {stats['skipped']}")
            print(f"  Failed: {stats['failed']}")
            
            # Save results to file if requested
            if args.output:
                output_path = Path(args.output)
                with open(output_path, 'w') as f:
                    json.dump(result, f, indent=2)
                print()
                print(f"Results saved to: {output_path}")
            
            sys.exit(0)
        else:
            print(f"❌ Pipeline failed: {result.get('error', 'Unknown error')}")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print()
        print("⚠️  Pipeline interrupted by user")
        sys.exit(130)
    except Exception as e:
        print()
        print(f"❌ Unexpected error: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
