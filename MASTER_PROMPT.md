# SR-OS AutoPost Remote Executor Node - Master Specification

## Overview
This specification defines the behavior, structure, and requirements for the SR-OS AutoPost Remote Executor Node, a Python-based automation tool that monitors a local folder and POSTs file contents to a remote SR-OS API endpoint.

---

## Section 1: Project Structure

The project MUST implement the following directory and file structure:

```
pulse-registry-system/
├── .github/
│   └── workflows/
│       ├── validate.yml          # CI validation workflow
│       └── heartbeat.yml         # Health monitoring workflow
├── deploy/
│   ├── run_autopost.bat          # Windows batch launcher
│   ├── sr-autopost-task.xml      # Windows Task Scheduler XML
│   ├── register_task.ps1         # PowerShell task registration
│   ├── run_autopost.sh           # Linux/macOS launcher
│   ├── run_autopost_health.sh    # Health check script
│   └── sr-autopost.service       # systemd service unit
├── scripts/
│   ├── heartbeat.py              # Health monitoring script
│   ├── build_zip.sh              # Linux/macOS package builder
│   └── build_zip.ps1             # Windows package builder
├── tests/
│   └── test_import.py            # Basic import and smoke tests
├── logs/
│   └── autopost_status.jsonl     # JSONL log file (initially empty)
├── autopost_client.py            # Main Python client application
├── config.example.json           # Example configuration file
├── posted_files.json             # Idempotency tracking (initially {})
├── requirements.txt              # Python dependencies
├── .gitignore                    # Git ignore patterns
├── README.md                     # Project documentation
├── CONTRIBUTING.md               # Contribution guidelines
├── COPILOT_AUTOPOST_AGENT.md    # Agent instructions
└── MASTER_PROMPT.md             # This specification file
```

---

## Section 2: Configuration Management

### config.json Structure
The application reads configuration from `config.json` (not tracked in git):

```json
{
  "api_url": "https://api.example.com/autopost",
  "api_key": "your-api-key-here",
  "watch_folder": "./watch_folder",
  "scan_interval_seconds": 60,
  "file_extensions": [".txt", ".json", ".log"],
  "max_file_size_mb": 10,
  "enable_logging": true,
  "log_file": "./logs/autopost_status.jsonl"
}
```

### Configuration Rules
1. If `config.json` does not exist, copy from `config.example.json` on first run
2. All paths are relative to the script location unless absolute
3. `watch_folder` is recursively scanned for files matching `file_extensions`
4. Files exceeding `max_file_size_mb` are skipped and logged as warnings

---

## Section 3: Behavior Contract

### 3.1 Core Functionality

#### autopost_client.py Requirements
The Python client MUST:
1. **Python Version**: Require Python 3.10 or higher
2. **HTTP Library**: Use `requests` library for all HTTP operations
3. **CLI Interface**: Provide two commands:
   - `python autopost_client.py run` - Execute normal operation
   - `python autopost_client.py test` - Send dry-run test payload
4. **Recursive Scanning**: Recursively scan `watch_folder` for files
5. **File Filtering**: Only process files matching `file_extensions`
6. **Idempotency**: Track posted files in `posted_files.json` to prevent duplicates
7. **Logging**: Write to both console (stdout) and JSONL log file
8. **Error Handling**: Catch and log all errors with clear messages

### 3.2 POST Payload Format
Every POST request MUST use this exact JSON structure:

```json
{
  "node_id": "autopost-node-<hostname>",
  "timestamp": "2025-11-15T01:23:44.886Z",
  "file_path": "relative/path/to/file.txt",
  "file_name": "file.txt",
  "file_content": "base64-encoded-content-here",
  "file_size_bytes": 1024,
  "file_hash_sha256": "sha256-hash-of-content"
}
```

### 3.3 Test Mode Behavior
When invoked with `python autopost_client.py test`:
1. Generate a safe test payload with dummy data
2. POST to the configured API endpoint
3. Log the response (success or error)
4. Exit with status code 0 on success, non-zero on failure
5. DO NOT scan or process actual files

### 3.4 Run Mode Behavior
When invoked with `python autopost_client.py run`:
1. Load configuration from `config.json`
2. Load posted files tracking from `posted_files.json`
3. Recursively scan `watch_folder` for matching files
4. For each NEW file (not in `posted_files.json`):
   - Read and base64-encode content
   - Calculate SHA256 hash
   - Build POST payload per Section 3.2
   - POST to `api_url` with `api_key` in header
   - On success: Add to `posted_files.json` and log success
   - On failure: Log error but continue processing other files
5. Save updated `posted_files.json`
6. Log summary: files found, files posted, files skipped, errors

### 3.5 Idempotency Tracking
The `posted_files.json` structure:

```json
{
  "relative/path/to/file1.txt": {
    "posted_at": "2025-11-15T01:23:44.886Z",
    "file_hash": "sha256-hash",
    "status": "success"
  },
  "relative/path/to/file2.json": {
    "posted_at": "2025-11-15T01:23:45.123Z",
    "file_hash": "sha256-hash",
    "status": "success"
  }
}
```

### 3.6 Logging Format
Console output MUST be clear and informative:
```
[2025-11-15T01:23:44.886Z] INFO: Starting SR-OS AutoPost Client (run mode)
[2025-11-15T01:23:44.887Z] INFO: Configuration loaded from config.json
[2025-11-15T01:23:44.888Z] INFO: Scanning watch_folder: ./watch_folder
[2025-11-15T01:23:44.889Z] INFO: Found 3 files matching extensions
[2025-11-15T01:23:44.890Z] INFO: Processing file: data/test.txt (1.2 KB)
[2025-11-15T01:23:45.100Z] SUCCESS: Posted data/test.txt (response: 200)
[2025-11-15T01:23:45.101Z] INFO: Processing file: data/test2.json (0.5 KB)
[2025-11-15T01:23:45.300Z] ERROR: Failed to post data/test2.json (error: 500 Internal Server Error)
[2025-11-15T01:23:45.301Z] INFO: Summary - Found: 3, Posted: 1, Skipped: 1, Errors: 1
```

JSONL log file MUST contain one JSON object per line:
```json
{"timestamp": "2025-11-15T01:23:44.886Z", "level": "INFO", "message": "Starting SR-OS AutoPost Client (run mode)"}
{"timestamp": "2025-11-15T01:23:45.100Z", "level": "SUCCESS", "file": "data/test.txt", "status": 200, "message": "Posted successfully"}
{"timestamp": "2025-11-15T01:23:45.300Z", "level": "ERROR", "file": "data/test2.json", "error": "500 Internal Server Error", "message": "Failed to post"}
```

---

## Section 4: Cross-Cutting Requirements

### 4.1 LIVE-Only Operation
- This system operates in LIVE mode ONLY
- All POSTs are real and affect production systems
- NO simulation or mock modes (except `test` command for validation)
- Implement idempotency to prevent duplicate posts

### 4.2 Platform Independence
- All scripts MUST support Windows, Linux, and macOS
- Use platform-agnostic Python standard library functions
- Provide platform-specific deployment files in `deploy/`
- Test on Python 3.10, 3.11, and 3.12

### 4.3 Transparency
- All operations MUST be logged clearly
- Success and failure states MUST be distinguishable
- Errors MUST include actionable information
- Support `--verbose` flag for detailed debugging output

### 4.4 Non-Destructive Behavior
- NEVER delete or modify source files in `watch_folder`
- NEVER overwrite `config.json` after initial creation
- Gracefully handle missing or malformed configuration
- Safe error handling with no data loss

### 4.5 Security
- API keys stored in `config.json` (excluded from git)
- No credentials in code or logs
- Validate file sizes before processing
- Sanitize file paths to prevent directory traversal

---

## Section 5: Deployment Requirements

### 5.1 Windows Deployment
- `run_autopost.bat`: Launches Python with proper environment
- `sr-autopost-task.xml`: Task Scheduler configuration for scheduled execution
- `register_task.ps1`: PowerShell script to register the scheduled task

### 5.2 Linux/macOS Deployment
- `run_autopost.sh`: Bash launcher with environment setup
- `sr-autopost.service`: systemd service unit for daemon mode
- `run_autopost_health.sh`: Health check script for monitoring

### 5.3 Build Scripts
- `build_zip.sh`: Creates deployment package on Linux/macOS
- `build_zip.ps1`: Creates deployment package on Windows
- Both scripts MUST include all necessary files and exclude dev dependencies

---

## Section 6: Testing Requirements

### 6.1 Basic Tests
- `test_import.py`: Verify Python imports work correctly
- Test configuration loading and validation
- Test file scanning logic
- Test payload generation
- Test idempotency tracking

### 6.2 CI/CD Integration
- `validate.yml`: Runs on every push, validates Python syntax and imports
- `heartbeat.yml`: Scheduled job to verify service health
- Both workflows MUST support Python 3.10+

---

## Section 7: Documentation Requirements

### 7.1 README.md
MUST include:
- Project overview and purpose
- Installation instructions
- Configuration guide
- Usage examples (`run` and `test` commands)
- Deployment instructions for each platform
- Troubleshooting section
- License information

### 7.2 CONTRIBUTING.md
MUST include:
- Code style guidelines
- Testing requirements
- Pull request process
- Issue reporting guidelines

### 7.3 COPILOT_AUTOPOST_AGENT.md
MUST include:
- Agent instructions for GitHub Copilot
- Common tasks and patterns
- Best practices for extending the system

---

## Section 8: Dependencies

### 8.1 Python Dependencies (requirements.txt)
```
requests>=2.31.0
```

### 8.2 System Requirements
- Python 3.10 or higher
- Internet connectivity for API access
- File system read access to `watch_folder`
- File system write access for logs and tracking files

---

## Section 9: Success Criteria

The implementation is complete when:
1. All files from Section 1 exist and are properly structured
2. `python autopost_client.py test` successfully sends a test payload
3. `python autopost_client.py run` scans files and maintains idempotency
4. All deployment scripts are platform-appropriate and functional
5. CI/CD workflows pass validation
6. Documentation is complete and accurate
7. The system operates transparently with clear logging
8. No security vulnerabilities are present

---

## Section 10: Maintenance and Extension

### 10.1 Adding New Features
- Follow existing code patterns
- Update documentation
- Add tests for new functionality
- Maintain backward compatibility with `config.json`

### 10.2 Monitoring
- Check `logs/autopost_status.jsonl` for operational status
- Use `heartbeat.py` for automated health checks
- Monitor API response codes and error patterns

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-15  
**Status**: CANONICAL SPECIFICATION
