#!/usr/bin/env python3
"""
SR-OS AutoPost Remote Executor Node - Basic Import Tests

This test suite verifies that the autopost_client module can be imported
and basic functionality is accessible.
"""

import sys
import os
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))


def test_python_version():
    """Test that Python version is 3.10 or higher"""
    assert sys.version_info >= (3, 10), f"Python 3.10+ required, found {sys.version_info.major}.{sys.version_info.minor}"
    print(f"✓ Python version check passed: {sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")


def test_requests_import():
    """Test that requests library is available"""
    try:
        import requests
        print(f"✓ requests library available: {requests.__version__}")
    except ImportError:
        assert False, "requests library not installed"


def test_autopost_client_import():
    """Test that autopost_client module can be imported"""
    try:
        import autopost_client
        print("✓ autopost_client module imported successfully")
    except ImportError as e:
        assert False, f"Failed to import autopost_client: {e}"


def test_autopost_client_class():
    """Test that AutoPostClient class exists"""
    import autopost_client
    assert hasattr(autopost_client, 'AutoPostClient'), "AutoPostClient class not found"
    print("✓ AutoPostClient class exists")


def test_autopost_client_methods():
    """Test that AutoPostClient has required methods"""
    import autopost_client
    
    required_methods = ['run', 'test', 'scan_files', 'post_file', 'log', 'build_payload']
    
    for method in required_methods:
        assert hasattr(autopost_client.AutoPostClient, method), f"Method '{method}' not found"
    
    print(f"✓ All required methods present: {', '.join(required_methods)}")


def test_config_example_exists():
    """Test that config.example.json exists"""
    config_example = Path(__file__).parent.parent / "config.example.json"
    assert config_example.exists(), "config.example.json not found"
    print("✓ config.example.json exists")


def test_config_example_valid_json():
    """Test that config.example.json is valid JSON"""
    import json
    
    config_example = Path(__file__).parent.parent / "config.example.json"
    
    try:
        with open(config_example, 'r') as f:
            config = json.load(f)
        
        # Check required keys
        required_keys = ['api_url', 'api_key', 'watch_folder', 'file_extensions']
        for key in required_keys:
            assert key in config, f"Required key '{key}' not in config.example.json"
        
        print(f"✓ config.example.json is valid JSON with required keys")
    
    except json.JSONDecodeError as e:
        assert False, f"config.example.json is not valid JSON: {e}"


def test_posted_files_json_exists():
    """Test that posted_files.json exists"""
    posted_files = Path(__file__).parent.parent / "posted_files.json"
    assert posted_files.exists(), "posted_files.json not found"
    print("✓ posted_files.json exists")


def test_requirements_txt_exists():
    """Test that requirements.txt exists"""
    requirements = Path(__file__).parent.parent / "requirements.txt"
    assert requirements.exists(), "requirements.txt not found"
    
    with open(requirements, 'r') as f:
        content = f.read()
        assert 'requests' in content, "requests not in requirements.txt"
    
    print("✓ requirements.txt exists and contains 'requests'")


def test_readme_exists():
    """Test that README.md exists"""
    readme = Path(__file__).parent.parent / "README.md"
    assert readme.exists(), "README.md not found"
    print("✓ README.md exists")


def test_master_prompt_exists():
    """Test that MASTER_PROMPT.md exists"""
    master_prompt = Path(__file__).parent.parent / "MASTER_PROMPT.md"
    assert master_prompt.exists(), "MASTER_PROMPT.md not found"
    print("✓ MASTER_PROMPT.md exists")


def run_all_tests():
    """Run all tests"""
    tests = [
        test_python_version,
        test_requests_import,
        test_autopost_client_import,
        test_autopost_client_class,
        test_autopost_client_methods,
        test_config_example_exists,
        test_config_example_valid_json,
        test_posted_files_json_exists,
        test_requirements_txt_exists,
        test_readme_exists,
        test_master_prompt_exists,
    ]
    
    print("Running SR-OS AutoPost Import Tests")
    print("=" * 50)
    print()
    
    passed = 0
    failed = 0
    
    for test in tests:
        try:
            test()
            passed += 1
        except AssertionError as e:
            print(f"✗ {test.__name__}: {e}")
            failed += 1
        except Exception as e:
            print(f"✗ {test.__name__}: Unexpected error: {e}")
            failed += 1
    
    print()
    print("=" * 50)
    print(f"Results: {passed} passed, {failed} failed")
    print()
    
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(run_all_tests())
