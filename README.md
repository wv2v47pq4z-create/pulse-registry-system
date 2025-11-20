# SR-OS AutoPost Remote Executor Node

A Python-based automation tool that monitors a local folder and POSTs file contents to a remote SR-OS API endpoint with idempotency tracking and comprehensive logging.

## Overview

The SR-OS AutoPost Remote Executor Node is designed for the Super Reality Studios blockchain ecosystem, enabling automated file upload and processing to remote SR-OS endpoints. It provides:

- **Automated File Monitoring**: Recursively scans a configured watch folder
- **Idempotency**: Tracks posted files to prevent duplicates
- **Platform Independence**: Works on Windows, Linux, macOS, and GitHub Codespaces
- **Transparent Logging**: Console and JSONL file logging
- **Secure**: API key authentication, file size limits, path sanitization

## Requirements

- Python 3.10 or higher
- Internet connectivity for API access
- File system read access to watch folder
- File system write access for logs and tracking

## Installation

### 1. Clone Repository

```bash
git clone https://github.com/wv2v47pq4z-create/pulse-registry-system.git
cd pulse-registry-system
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

Or using a virtual environment (recommended):

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Configure

Copy the example configuration and edit with your settings:

```bash
cp config.example.json config.json
```

Edit `config.json` with your actual API endpoint and key:

```json
{
  "api_url": "https://your-api-endpoint.com/autopost",
  "api_key": "your-actual-api-key",
  "watch_folder": "./watch_folder",
  "scan_interval_seconds": 60,
  "file_extensions": [".txt", ".json", ".log"],
  "max_file_size_mb": 10,
  "enable_logging": true,
  "log_file": "./logs/autopost_status.jsonl"
}
```

### 4. Create Watch Folder

```bash
mkdir watch_folder
```

## Usage

### Test Mode

Verify your configuration by sending a test payload:

```bash
python autopost_client.py test
```

This sends a safe test payload to your configured API endpoint without processing any actual files.

### Run Mode

Execute normal operation to scan and post files:

```bash
python autopost_client.py run
```

This will:
1. Load configuration from `config.json`
2. Load tracking data from `posted_files.json`
3. Recursively scan `watch_folder` for matching files
4. POST each new file to the API endpoint
5. Track posted files to prevent duplicates
6. Log all operations to console and JSONL file

## Configuration Options

| Option | Type | Description |
|--------|------|-------------|
| `api_url` | string | Remote SR-OS API endpoint URL |
| `api_key` | string | API authentication key |
| `watch_folder` | string | Folder to monitor for files (relative or absolute) |
| `scan_interval_seconds` | number | Scan interval (for scheduled execution) |
| `file_extensions` | array | List of file extensions to process (e.g., `[".txt", ".json"]`) |
| `max_file_size_mb` | number | Maximum file size in MB (files larger are skipped) |
| `enable_logging` | boolean | Enable JSONL file logging |
| `log_file` | string | Path to JSONL log file |

## Deployment

### Windows

#### Manual Execution

```batch
cd pulse-registry-system
deploy\run_autopost.bat
```

#### Scheduled Task

Register a Windows Scheduled Task for automated execution:

```powershell
.\deploy\register_task.ps1
```

This creates a scheduled task that runs the autopost client periodically.

### Linux/macOS

#### Manual Execution

```bash
cd pulse-registry-system
./deploy/run_autopost.sh
```

#### systemd Service

For daemon mode on Linux:

```bash
sudo cp deploy/sr-autopost.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable sr-autopost.service
sudo systemctl start sr-autopost.service
```

Check status:

```bash
sudo systemctl status sr-autopost.service
```

#### Health Check

Run the health check script:

```bash
./deploy/run_autopost_health.sh
```

### GitHub Codespaces

The client works seamlessly in GitHub Codespaces. Simply follow the standard installation and usage instructions.

## Logging

### Console Output

All operations are logged to the console with timestamps and severity levels:

```
[2025-11-15T01:23:44.886Z] INFO: Starting SR-OS AutoPost Client (run mode)
[2025-11-15T01:23:44.887Z] INFO: Configuration loaded from config.json
[2025-11-15T01:23:44.888Z] INFO: Scanning watch_folder: ./watch_folder
[2025-11-15T01:23:44.889Z] INFO: Found 3 files matching extensions
[2025-11-15T01:23:45.100Z] SUCCESS: Posted data/test.txt (response: 200)
[2025-11-15T01:23:45.300Z] ERROR: Failed to post data/test2.json (error: 500)
[2025-11-15T01:23:45.301Z] INFO: Summary - Found: 3, Posted: 1, Skipped: 1, Errors: 1
```

### JSONL Log File

Structured logs are written to `logs/autopost_status.jsonl` (one JSON object per line):

```json
{"timestamp": "2025-11-15T01:23:44.886Z", "level": "INFO", "message": "Starting SR-OS AutoPost Client (run mode)"}
{"timestamp": "2025-11-15T01:23:45.100Z", "level": "SUCCESS", "file": "data/test.txt", "status": 200, "message": "Posted successfully"}
```

## Idempotency

The system tracks posted files in `posted_files.json` to prevent duplicates:

```json
{
  "data/test.txt": {
    "posted_at": "2025-11-15T01:23:45.100Z",
    "file_hash": "sha256-hash-here",
    "status": "success"
  }
}
```

Files already in this tracking file are skipped during subsequent runs.

## Troubleshooting

### "ERROR: 'requests' library not found"

Install dependencies:

```bash
pip install -r requirements.txt
```

### "ERROR: Neither config.json nor config.example.json found"

Ensure `config.example.json` exists, or create `config.json` manually with the required structure.

### "WARNING: Watch folder does not exist"

Create the watch folder:

```bash
mkdir watch_folder
```

### "ERROR: Failed to post ... (error: 401 Unauthorized)"

Check your `api_key` in `config.json` is correct.

### "ERROR: Failed to post ... (error: Connection refused)"

Verify the `api_url` in `config.json` is correct and the API endpoint is accessible.

### Files Not Being Posted

1. Check file extensions match `file_extensions` in config
2. Verify files aren't already in `posted_files.json`
3. Check file size doesn't exceed `max_file_size_mb`
4. Review logs in `logs/autopost_status.jsonl`

## Building Deployment Packages

### Linux/macOS

```bash
./scripts/build_zip.sh
```

Creates `sr-autopost-deploy.zip` with all necessary files.

### Windows

```powershell
.\scripts\build_zip.ps1
```

Creates `sr-autopost-deploy.zip` with all necessary files.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to this project.

## License

See [LICENSE](LICENSE) for license information.

## Support

For issues and feature requests, please use the GitHub issue tracker.

## Project Structure

```
pulse-registry-system/
├── autopost_client.py        # Main client application
├── config.example.json        # Example configuration
├── posted_files.json          # Idempotency tracking
├── requirements.txt           # Python dependencies
├── deploy/                    # Deployment scripts
├── scripts/                   # Helper scripts
├── tests/                     # Test suite
├── logs/                      # Log files
└── .github/workflows/         # CI/CD workflows
```

## Related Projects

- PulseRegistry Smart Contracts
- ZcashBridge Integration
- Super Reality Studios Blockchain Ecosystem

---

**Version**: 1.0  
**Last Updated**: 2025-11-15
