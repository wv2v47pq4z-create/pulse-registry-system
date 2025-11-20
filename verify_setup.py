#!/usr/bin/env python3
"""
Quick verification script to check if the pipeline is properly set up.
Run this to verify your environment before running the full pipeline.
"""
import sys
import importlib.util
from pathlib import Path


def check_module(module_name):
    """Check if a Python module is available."""
    spec = importlib.util.find_spec(module_name)
    return spec is not None


def main():
    print("=" * 70)
    print("AUTONOMOUS RESEARCH PIPELINE - SETUP VERIFICATION")
    print("=" * 70)
    print()
    
    # Check Python version
    print("1. Checking Python version...")
    version = sys.version_info
    if version.major == 3 and version.minor >= 11:
        print(f"   ✅ Python {version.major}.{version.minor}.{version.micro}")
    else:
        print(f"   ⚠️  Python {version.major}.{version.minor}.{version.micro}")
        print(f"   Recommended: Python 3.11+")
    print()
    
    # Check required modules
    print("2. Checking required dependencies...")
    required_modules = {
        "requests": "HTTP library for API calls",
        "pyairtable": "Airtable integration",
        "pydantic": "Data validation",
        "dotenv": "Environment variable management"
    }
    
    all_present = True
    for module, description in required_modules.items():
        if check_module(module):
            print(f"   ✅ {module:15} - {description}")
        else:
            print(f"   ❌ {module:15} - {description} [MISSING]")
            all_present = False
    print()
    
    if not all_present:
        print("⚠️  Missing dependencies detected!")
        print("   Run: pip install -r requirements.txt")
        print()
    
    # Check pipeline modules
    print("3. Checking pipeline modules...")
    pipeline_modules = ["models", "claude_api", "pipeline", "main"]
    all_modules_ok = True
    
    for module in pipeline_modules:
        try:
            __import__(module)
            print(f"   ✅ {module}.py")
        except Exception as e:
            print(f"   ❌ {module}.py - Error: {str(e)}")
            all_modules_ok = False
    print()
    
    # Check environment configuration
    print("4. Checking environment configuration...")
    try:
        env_file = Path(".env")
        env_example = Path(".env.example")
        
        if env_file.exists():
            print("   ✅ .env file found")
        else:
            print("   ⚠️  .env file not found")
            if env_example.exists():
                print("      Copy .env.example to .env and configure your API keys")
        
        if env_example.exists():
            print("   ✅ .env.example found")
    except Exception as e:
        print(f"   ❌ Error checking environment: {e}")
    print()
    
    # Check Docker files
    print("5. Checking Docker configuration...")
    try:
        dockerfile = Path("Dockerfile")
        compose = Path("docker-compose.yml")
        
        if dockerfile.exists():
            print("   ✅ Dockerfile found")
        else:
            print("   ❌ Dockerfile not found")
            
        if compose.exists():
            print("   ✅ docker-compose.yml found")
        else:
            print("   ❌ docker-compose.yml not found")
    except Exception as e:
        print(f"   ❌ Error checking Docker files: {e}")
    print()
    
    # Summary
    print("=" * 70)
    print("VERIFICATION SUMMARY")
    print("=" * 70)
    
    if all_present and all_modules_ok:
        print("✅ Setup verification complete!")
        print()
        print("Next steps:")
        print("  1. Configure .env with your API keys")
        print("  2. Set up your Airtable base")
        print("  3. Run: python main.py --validate-only")
        print("  4. Run: python main.py")
        print()
        print("For detailed documentation, see:")
        print("  - PIPELINE_README.md (Python implementation)")
        print("  - MAKECOM_INTEGRATION.md (No-code automation)")
        return 0
    else:
        print("⚠️  Some issues detected. Please resolve them before running the pipeline.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
