# SR-OS AutoPost Remote Executor Node - Deployment Guide

## Quick Start Deployment

The SR-OS AutoPost Remote Executor Node is ready for deployment. A deployment package has been created: **sr-autopost-deploy.zip** (35KB)

## Deployment Options

### Option 1: Direct Deployment from Repository

For direct deployment in your environment:

```bash
# Clone the repository
git clone https://github.com/wv2v47pq4z-create/pulse-registry-system.git
cd pulse-registry-system

# Install dependencies
pip install -r requirements.txt

# Configure
cp config.example.json config.json
# Edit config.json with your API endpoint and credentials

# Test the configuration
python autopost_client.py test

# Run in production
python autopost_client.py run
```

### Option 2: Using Deployment Package

Download the deployment package **sr-autopost-deploy.zip** and extract it:

```bash
# Extract the package
unzip sr-autopost-deploy.zip -d sr-autopost
cd sr-autopost

# Install dependencies
pip install -r requirements.txt

# Configure
cp config.example.json config.json
# Edit config.json with your API endpoint and credentials

# Test the configuration
python autopost_client.py test

# Run in production
python autopost_client.py run
```

## Platform-Specific Deployment

### Windows Deployment

#### Manual Execution

```batch
cd pulse-registry-system
deploy\run_autopost.bat
```

#### Scheduled Task (Automated)

For automated periodic execution:

```powershell
# Run PowerShell as Administrator
cd pulse-registry-system
.\deploy\register_task.ps1
```

This will:
- Register a Windows Scheduled Task
- Configure it to run every hour (configurable)
- Set up logging and error handling
- Enable task management through Windows Task Scheduler

**Verify Task:**
```powershell
Get-ScheduledTask -TaskName "SR-OS AutoPost Client"
```

**Start Task Manually:**
```powershell
Start-ScheduledTask -TaskName "SR-OS AutoPost Client"
```

### Linux/macOS Deployment

#### Manual Execution

```bash
cd pulse-registry-system
./deploy/run_autopost.sh
```

#### systemd Service (Linux Daemon)

For automated daemon mode on Linux:

**Step 1: Install the service**
```bash
sudo cp deploy/sr-autopost.service /etc/systemd/system/
sudo systemctl daemon-reload
```

**Step 2: Configure the service**

Edit the service file to set the correct installation path:
```bash
sudo nano /etc/systemd/system/sr-autopost.service
```

Update `WorkingDirectory` and `ExecStart` paths to match your installation.

**Step 3: Enable and start the service**
```bash
sudo systemctl enable sr-autopost.service
sudo systemctl start sr-autopost.service
```

**Step 4: Verify status**
```bash
sudo systemctl status sr-autopost.service
sudo journalctl -u sr-autopost.service -f
```

#### Health Check

Run the health check script to verify your deployment:

```bash
./deploy/run_autopost_health.sh
```

This will verify:
- Python version compatibility
- Dependencies installation
- Configuration validity
- Watch folder existence
- Logging setup
- Recent activity

### GitHub Codespaces Deployment

The client works seamlessly in GitHub Codespaces:

```bash
# Codespaces environment is pre-configured
pip install -r requirements.txt
cp config.example.json config.json
# Edit config.json with your settings
python autopost_client.py test
```

## Configuration

### Required Configuration Fields

Edit `config.json` with your deployment settings:

```json
{
  "api_url": "https://your-actual-api-endpoint.com/autopost",
  "api_key": "your-production-api-key",
  "watch_folder": "./watch_folder",
  "scan_interval_seconds": 60,
  "file_extensions": [".txt", ".json", ".log"],
  "max_file_size_mb": 10,
  "enable_logging": true,
  "log_file": "./logs/autopost_status.jsonl"
}
```

### Configuration Best Practices

1. **API Credentials**: Never commit `config.json` to version control
2. **Watch Folder**: Ensure the folder exists and has appropriate permissions
3. **File Extensions**: Only include extensions you need to process
4. **File Size Limits**: Set appropriate limits based on your API constraints
5. **Logging**: Enable logging for production monitoring

## Post-Deployment Verification

### 1. Test Mode

Always test your configuration before production:

```bash
python autopost_client.py test
```

Expected output:
```
[TIMESTAMP] INFO: Configuration loaded from config.json
[TIMESTAMP] INFO: Starting SR-OS AutoPost Client (test mode)
[TIMESTAMP] INFO: Sending test payload to: https://your-api.com/autopost
[TIMESTAMP] SUCCESS: Test payload sent successfully (response: 200)
```

### 2. Health Check

Run the heartbeat monitor:

```bash
python scripts/heartbeat.py
```

Expected output:
```
SR-OS AutoPost Heartbeat Monitor
========================================
Overall Status: ✓ HEALTHY

✓ python_version: Python 3.10+
✓ dependencies: requests installed
✓ configuration: Valid
✓ watch_folder: Exists
✓ logs: Accessible
✓ tracking: Operational
```

### 3. Import Tests

Verify all components:

```bash
python tests/test_import.py
```

Expected: 11/11 tests passed

## Monitoring and Maintenance

### Log Files

**Console Logs**: Real-time output during execution

**JSONL Logs**: Structured logs in `logs/autopost_status.jsonl`

```bash
# View recent logs
tail -f logs/autopost_status.jsonl

# Parse logs with jq
cat logs/autopost_status.jsonl | jq .

# Filter errors
grep "ERROR" logs/autopost_status.jsonl
```

### Tracking Files

**posted_files.json**: Tracks all successfully posted files

```bash
# View tracked files
cat posted_files.json | jq .

# Count posted files
cat posted_files.json | jq 'length'
```

### Automated Health Checks

Set up periodic health checks:

**Linux Cron:**
```bash
# Add to crontab
0 * * * * /path/to/pulse-registry-system/scripts/heartbeat.py --json >> /var/log/sr-autopost-health.log 2>&1
```

**Windows Task Scheduler:**
Use the same `register_task.ps1` script with modified XML for health checks.

## Troubleshooting

### Common Issues

**Issue: "ERROR: requests library not found"**
```bash
pip install -r requirements.txt
```

**Issue: "WARNING: Watch folder does not exist"**
```bash
mkdir -p watch_folder
```

**Issue: "ERROR: Failed to post ... (error: 401 Unauthorized)"**
- Verify `api_key` in config.json
- Check API endpoint is correct
- Ensure API key has proper permissions

**Issue: "ERROR: Failed to post ... (error: Connection refused)"**
- Verify `api_url` in config.json
- Check network connectivity
- Ensure API endpoint is accessible

### Debug Mode

For detailed debugging:

```bash
# Enable verbose output (if supported)
python autopost_client.py run --verbose

# Check Python version
python --version

# Test imports manually
python -c "import autopost_client; print('OK')"

# Verify configuration
python -c "import json; print(json.dumps(json.load(open('config.json')), indent=2))"
```

## Security Considerations

### Production Deployment Checklist

- [ ] API credentials stored securely in `config.json`
- [ ] `config.json` added to `.gitignore`
- [ ] File size limits configured appropriately
- [ ] Watch folder has restricted permissions
- [ ] Logs directory has appropriate permissions
- [ ] Service runs with minimal required privileges
- [ ] Network access restricted to API endpoint only
- [ ] Regular security updates applied

### Credentials Management

**Never:**
- Commit `config.json` to version control
- Include API keys in logs
- Share deployment packages with credentials

**Always:**
- Use environment-specific configuration files
- Rotate API keys regularly
- Monitor logs for security events
- Apply principle of least privilege

## Scaling and Performance

### Single Instance

- Suitable for: Small to medium workloads
- Processes files sequentially
- Maintains idempotency per instance

### Multiple Instances

For high-volume scenarios:

1. **Separate Watch Folders**: Each instance monitors different folders
2. **Shared Tracking**: Use centralized tracking system (future enhancement)
3. **Load Balancing**: Distribute files across instances

### Performance Tuning

- Adjust `scan_interval_seconds` based on workload
- Set appropriate `max_file_size_mb` limits
- Monitor system resources (CPU, memory, network)
- Use dedicated infrastructure for production

## Backup and Recovery

### Critical Files

Backup these files regularly:

- `config.json` (encrypted backup)
- `posted_files.json` (for idempotency tracking)
- `logs/autopost_status.jsonl` (for audit trail)

### Recovery Procedures

**Lost Tracking Data:**
```bash
# Restore from backup
cp posted_files.json.backup posted_files.json

# Or reset (will reprocess all files)
echo "{}" > posted_files.json
```

**Configuration Reset:**
```bash
# Restore from example
cp config.example.json config.json
# Edit with production values
```

## Support and Documentation

- **README.md**: User documentation and quick start
- **MASTER_PROMPT.md**: Complete specification
- **CONTRIBUTING.md**: Development guidelines
- **COPILOT_AUTOPOST_AGENT.md**: Agent instructions

## Deployment Package Contents

The deployment package includes:

- autopost_client.py (main application)
- config.example.json (configuration template)
- requirements.txt (Python dependencies)
- deploy/ (platform-specific deployment scripts)
- scripts/ (helper utilities)
- tests/ (test suite)
- .github/workflows/ (CI/CD configuration)
- Documentation files

## Next Steps After Deployment

1. ✅ Configure `config.json` with production values
2. ✅ Create `watch_folder` directory
3. ✅ Run `python autopost_client.py test` to verify
4. ✅ Set up automated execution (Task Scheduler/systemd)
5. ✅ Configure monitoring and alerts
6. ✅ Test with sample files
7. ✅ Monitor logs for first few runs
8. ✅ Document deployment-specific notes

---

**Deployment Package Version**: 1.0  
**Last Updated**: 2025-11-20  
**Package Size**: 35KB  
**Platform Support**: Windows, Linux, macOS, GitHub Codespaces
