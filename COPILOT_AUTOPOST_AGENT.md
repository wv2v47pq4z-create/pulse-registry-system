# GitHub Copilot Agent Instructions - SR-OS AutoPost

## Agent Context

You are assisting with the SR-OS AutoPost Remote Executor Node, a Python-based automation tool for the Super Reality Studios blockchain ecosystem. This tool monitors local folders and POSTs file contents to remote API endpoints.

## Key Architectural Principles

### 1. Idempotency First
- Always track posted files in `posted_files.json`
- Never post the same file twice
- Check tracking before processing

### 2. Transparent Operation
- Log every action with timestamp
- Use both console and JSONL logging
- Provide clear error messages

### 3. Platform Independence
- Support Windows, Linux, macOS, and Codespaces
- Use `pathlib.Path` for file operations
- Avoid platform-specific commands in core logic

### 4. Non-Destructive Behavior
- Never modify or delete source files
- Safe error handling
- Graceful degradation

## Common Development Tasks

### Adding a New Configuration Option

1. Add to `config.example.json` with default value
2. Update schema in MASTER_PROMPT.md Section 2
3. Access in code via `self.config.get("option_name", default_value)`
4. Document in README.md Configuration Options table
5. Add validation in `_load_config()` if needed

Example:
```python
# In autopost_client.py
retry_count = self.config.get("max_retries", 3)
```

### Adding a New Log Level

Current levels: INFO, SUCCESS, WARNING, ERROR

To add a new level:
1. Use in `self.log("LEVEL", "message", **kwargs)`
2. Document in MASTER_PROMPT.md Section 3.6
3. Update README.md logging examples
4. Ensure JSONL format consistency

### Extending File Processing

When modifying file processing logic:

```python
def process_file(self, file_path: Path) -> bool:
    """
    Process a single file
    
    Args:
        file_path: Path to file to process
    
    Returns:
        True if successful, False otherwise
    """
    # 1. Check if already posted
    if self._is_already_posted(file_path):
        return False
    
    # 2. Read and validate
    content = self._read_file(file_path)
    
    # 3. Build payload
    payload = self.build_payload(file_path, content)
    
    # 4. POST to API
    success = self._post_payload(payload)
    
    # 5. Track if successful
    if success:
        self._track_posted_file(file_path)
    
    return success
```

### Adding New CLI Commands

Current commands: `run`, `test`

To add a new command:

1. Add to argparse choices in `main()`:
   ```python
   parser.add_argument(
       "command",
       choices=["run", "test", "your_command"],
       help="Command to execute"
   )
   ```

2. Add method in `AutoPostClient`:
   ```python
   def your_command(self) -> int:
       """Your command description"""
       self.log("INFO", "Starting your command")
       # Implementation
       return 0  # or error code
   ```

3. Add to command dispatch in `main()`:
   ```python
   elif args.command == "your_command":
       return client.your_command()
   ```

4. Update documentation in README.md and MASTER_PROMPT.md

### Error Handling Pattern

Always use this pattern:

```python
try:
    # Operation that might fail
    result = risky_operation()
except SpecificException as e:
    self.log("ERROR", f"Operation failed: {e}")
    # Decide: continue, return, or exit
    return False
except Exception as e:
    self.log("ERROR", f"Unexpected error: {e}")
    return False
```

### Adding Tests

Create tests in `tests/` directory:

```python
import pytest
from autopost_client import AutoPostClient

def test_feature():
    """Test description"""
    # Arrange
    client = AutoPostClient()
    
    # Act
    result = client.method()
    
    # Assert
    assert result == expected
```

Run tests:
```bash
python -m pytest tests/ -v
```

## Code Patterns

### Configuration Loading

```python
value = self.config.get("key", default_value)
if not value:
    self.log("ERROR", "Required config key missing")
    sys.exit(1)
```

### File Path Handling

```python
from pathlib import Path

# Always use Path objects
file_path = Path(self.config.get("watch_folder")) / "subdir" / "file.txt"

# Get relative path for tracking
relative_path = str(file_path.relative_to(Path.cwd()))

# Normalize separators for cross-platform
normalized = relative_path.replace("\\", "/")
```

### Logging

```python
# Simple message
self.log("INFO", "Operation completed")

# With additional fields
self.log("SUCCESS", "File posted", file=file_path, status=200)

# Error with context
self.log("ERROR", f"Failed to process {file_path}", error=str(e))
```

### HTTP Requests

```python
headers = {
    "Content-Type": "application/json",
}

if self.config.get("api_key"):
    headers["Authorization"] = f"Bearer {self.config['api_key']}"

response = requests.post(
    self.config["api_url"],
    json=payload,
    headers=headers,
    timeout=30
)

if response.status_code in [200, 201, 202]:
    # Success
    pass
else:
    # Handle error
    self.log("ERROR", f"HTTP {response.status_code}: {response.reason}")
```

## Debugging Tips

### Enable Verbose Logging

Add verbose flag support:
```python
if args.verbose:
    self.log("DEBUG", f"Detailed info: {details}")
```

### Test Individual Components

```python
# Test configuration loading
client = AutoPostClient()
print(json.dumps(client.config, indent=2))

# Test file scanning
files = client.scan_files()
print(f"Found {len(files)} files")

# Test payload building
payload = client.build_payload(Path("test.txt"), b"content")
print(json.dumps(payload, indent=2))
```

### Check Tracking File

```bash
cat posted_files.json | python -m json.tool
```

### Review Logs

```bash
# View all logs
cat logs/autopost_status.jsonl

# Filter by level
grep "ERROR" logs/autopost_status.jsonl

# Pretty print
cat logs/autopost_status.jsonl | jq .
```

## Security Considerations

### API Key Handling

```python
# ✓ GOOD - Use config file
api_key = self.config.get("api_key")

# ✗ BAD - Never hardcode
api_key = "sk-1234567890"  # DON'T DO THIS
```

### Path Validation

```python
def is_safe_path(base_path: Path, target_path: Path) -> bool:
    """Prevent directory traversal"""
    try:
        target_path.resolve().relative_to(base_path.resolve())
        return True
    except ValueError:
        return False
```

### File Size Limits

```python
max_size = self.config.get("max_file_size_mb", 10) * 1024 * 1024
if file_path.stat().st_size > max_size:
    self.log("WARNING", f"File too large: {file_path}")
    return False
```

## Best Practices

### 1. Type Hints

Always use type hints:
```python
def method(param: str) -> bool:
    pass
```

### 2. Docstrings

Document all public methods:
```python
def method(param: str) -> bool:
    """
    Brief description.
    
    Args:
        param: Description
    
    Returns:
        Description
    """
    pass
```

### 3. Constants

Define constants at module level:
```python
DEFAULT_TIMEOUT = 30
MAX_FILE_SIZE_MB = 10
SUPPORTED_EXTENSIONS = [".txt", ".json", ".log"]
```

### 4. Error Messages

Make them actionable:
```python
# ✓ GOOD
self.log("ERROR", "API key not found in config.json. Add 'api_key' field.")

# ✗ BAD
self.log("ERROR", "Missing key")
```

### 5. Testing Before Committing

```bash
# Run tests
python -m pytest tests/ -v

# Test CLI
python autopost_client.py test

# Verify imports
python -c "import autopost_client"
```

## Common Pitfalls

### 1. Path Separators

```python
# ✗ BAD - Platform specific
path = "folder\\file.txt"

# ✓ GOOD - Cross-platform
path = Path("folder") / "file.txt"
```

### 2. Absolute vs Relative Paths

```python
# Always normalize for tracking
relative = str(file_path.relative_to(Path.cwd())).replace("\\", "/")
```

### 3. JSON Encoding

```python
# ✗ BAD - Bytes not JSON serializable
payload["content"] = file_bytes

# ✓ GOOD - Base64 encode
payload["content"] = base64.b64encode(file_bytes).decode('utf-8')
```

### 4. Exception Handling

```python
# ✗ BAD - Silent failure
try:
    operation()
except:
    pass

# ✓ GOOD - Log and handle
try:
    operation()
except Exception as e:
    self.log("ERROR", f"Operation failed: {e}")
    return False
```

## Quick Reference

### File Structure
```
autopost_client.py       - Main application
config.example.json      - Example configuration
posted_files.json        - Idempotency tracking
requirements.txt         - Dependencies
MASTER_PROMPT.md        - Canonical specification
```

### Key Methods
- `run()` - Normal operation
- `test()` - Dry-run test
- `scan_files()` - Find files to process
- `post_file()` - POST single file
- `log()` - Logging

### Configuration Keys
- `api_url` - API endpoint
- `api_key` - Authentication
- `watch_folder` - Folder to monitor
- `file_extensions` - Extensions to process
- `max_file_size_mb` - Size limit

### Exit Codes
- `0` - Success
- `1` - Error
- `130` - Interrupted (Ctrl+C)

---

**Remember**: Always refer to MASTER_PROMPT.md as the canonical specification. When in doubt, check the specification first.
