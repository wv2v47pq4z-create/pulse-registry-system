# SR-OS AutoPost - Automated Deployment Guide (Method #3)

## Overview

This guide covers **Automated Deployment** - Method #3 from the deployment options. This method sets up the SR-OS AutoPost client to run automatically on a schedule using platform-native tools.

## Quick Setup

### Automated Setup Script

Run the automated setup script to get platform-specific instructions:

```bash
./deploy/setup_automated.sh
```

This script will:
1. ✓ Verify your configuration
2. ✓ Check dependencies
3. ✓ Test the connection (if configured)
4. ✓ Provide platform-specific setup instructions

## Platform-Specific Instructions

### Windows - Task Scheduler

**Step 1: Run PowerShell as Administrator**

```powershell
# Navigate to the project directory
cd path\to\pulse-registry-system

# Run the registration script
.\deploy\register_task.ps1
```

**Step 2: Verify the Task**

```powershell
# Check task status
Get-ScheduledTask -TaskName "SR-OS AutoPost Client"

# View task information
Get-ScheduledTask -TaskName "SR-OS AutoPost Client" | Get-ScheduledTaskInfo

# Manually trigger the task
Start-ScheduledTask -TaskName "SR-OS AutoPost Client"
```

**Configuration Options:**

The scheduled task is configured to:
- Run every hour (default, configurable in XML)
- Execute even if the user is not logged in
- Retry on failure
- Log all output

**Customization:**

Edit `deploy/sr-autopost-task.xml` before running `register_task.ps1`:
- Change the repetition interval (currently PT1H = 1 hour)
- Modify the execution time limit
- Adjust retry behavior

### Linux - systemd Service

**Step 1: Install the Service**

```bash
# Copy service file to systemd directory
sudo cp deploy/sr-autopost.service /etc/systemd/system/

# Reload systemd configuration
sudo systemctl daemon-reload
```

**Step 2: Configure the Service**

Edit the service file to match your installation path:

```bash
sudo nano /etc/systemd/system/sr-autopost.service
```

Update these lines:
```ini
WorkingDirectory=/opt/pulse-registry-system  # Your actual path
ExecStart=/usr/bin/python3 /opt/pulse-registry-system/autopost_client.py run
```

**Step 3: Enable and Start**

```bash
# Enable service to start on boot
sudo systemctl enable sr-autopost.service

# Start the service now
sudo systemctl start sr-autopost.service

# Check service status
sudo systemctl status sr-autopost.service
```

**Service Management:**

```bash
# Start the service
sudo systemctl start sr-autopost.service

# Stop the service
sudo systemctl stop sr-autopost.service

# Restart the service
sudo systemctl restart sr-autopost.service

# View logs
sudo journalctl -u sr-autopost.service -f

# View recent logs
sudo journalctl -u sr-autopost.service --since "1 hour ago"
```

**Timer-Based Execution (Alternative):**

For periodic execution instead of continuous running, create a timer unit:

```bash
sudo nano /etc/systemd/system/sr-autopost.timer
```

```ini
[Unit]
Description=SR-OS AutoPost Timer
Requires=sr-autopost.service

[Timer]
OnBootSec=5min
OnUnitActiveSec=1h

[Install]
WantedBy=timers.target
```

Enable the timer:
```bash
sudo systemctl enable sr-autopost.timer
sudo systemctl start sr-autopost.timer
```

### Linux - Cron (Alternative)

If systemd is not available, use cron:

**Step 1: Edit Crontab**

```bash
crontab -e
```

**Step 2: Add Cron Job**

Add this line to run every hour:

```cron
# SR-OS AutoPost - Run every hour
0 * * * * cd /path/to/pulse-registry-system && ./deploy/run_autopost.sh >> /var/log/sr-autopost.log 2>&1
```

Other schedule examples:
```cron
# Every 30 minutes
*/30 * * * * cd /path/to/pulse-registry-system && ./deploy/run_autopost.sh

# Every day at 2 AM
0 2 * * * cd /path/to/pulse-registry-system && ./deploy/run_autopost.sh

# Every 15 minutes during business hours (9 AM - 5 PM, Mon-Fri)
*/15 9-17 * * 1-5 cd /path/to/pulse-registry-system && ./deploy/run_autopost.sh
```

**Step 3: Verify Cron Job**

```bash
# List cron jobs
crontab -l

# Check cron logs (location varies by system)
grep CRON /var/log/syslog
```

### macOS - LaunchAgent

**Step 1: Create LaunchAgent plist**

```bash
nano ~/Library/LaunchAgents/com.sros.autopost.plist
```

**Step 2: Add Configuration**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.sros.autopost</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/python3</string>
        <string>/path/to/pulse-registry-system/autopost_client.py</string>
        <string>run</string>
    </array>
    
    <key>WorkingDirectory</key>
    <string>/path/to/pulse-registry-system</string>
    
    <key>StartInterval</key>
    <integer>3600</integer>
    
    <key>StandardOutPath</key>
    <string>/tmp/sr-autopost.log</string>
    
    <key>StandardErrorPath</key>
    <string>/tmp/sr-autopost.error.log</string>
    
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
```

**Step 3: Load LaunchAgent**

```bash
# Load the agent
launchctl load ~/Library/LaunchAgents/com.sros.autopost.plist

# Start the agent
launchctl start com.sros.autopost

# Check status
launchctl list | grep sros
```

**Management Commands:**

```bash
# Stop the agent
launchctl stop com.sros.autopost

# Unload the agent
launchctl unload ~/Library/LaunchAgents/com.sros.autopost.plist

# Reload after changes
launchctl unload ~/Library/LaunchAgents/com.sros.autopost.plist
launchctl load ~/Library/LaunchAgents/com.sros.autopost.plist
```

## Verification

### Test the Setup

Before enabling automation, test manually:

```bash
# Test mode (dry-run)
python autopost_client.py test

# Single execution
python autopost_client.py run

# Health check
python scripts/heartbeat.py

# Full health check with deployment verification
./deploy/run_autopost_health.sh
```

### Monitor Automated Execution

**Check Logs:**

```bash
# Application logs
tail -f logs/autopost_status.jsonl

# Parse with jq (if installed)
tail -f logs/autopost_status.jsonl | jq .

# Filter errors
grep ERROR logs/autopost_status.jsonl
```

**Check Tracking:**

```bash
# View posted files
cat posted_files.json | python3 -m json.tool

# Count posted files
cat posted_files.json | python3 -c "import json, sys; print(len(json.load(sys.stdin)))"
```

**Platform-Specific Logs:**

- **Windows Task Scheduler**: Check Task Scheduler History
- **Linux systemd**: `sudo journalctl -u sr-autopost.service`
- **Linux cron**: Check `/var/log/syslog` or `/var/log/cron`
- **macOS LaunchAgent**: Check `/tmp/sr-autopost.log`

## Troubleshooting

### Common Issues

**Issue: Task/Service not starting**
- Verify file paths are absolute and correct
- Check file permissions (executable bits)
- Verify Python is in PATH
- Check configuration file exists

**Issue: Authentication failures**
- Verify `api_key` in config.json
- Ensure config.json is readable by the service user
- Check API endpoint URL is correct

**Issue: Files not being processed**
- Verify `watch_folder` exists and has correct permissions
- Check file extensions match configuration
- Review `posted_files.json` for already-processed files
- Check file size limits

### Debug Mode

Enable verbose logging:

```bash
# View full Python traceback
python autopost_client.py run 2>&1 | tee debug.log

# Check systemd service with more detail (Linux)
sudo systemctl status sr-autopost.service -l --no-pager

# Run manually as the service user (Linux)
sudo -u autopost python3 autopost_client.py run
```

## Configuration for Automated Deployment

### Recommended Settings

For automated deployment, configure these settings in `config.json`:

```json
{
  "api_url": "https://your-production-api.com/autopost",
  "api_key": "your-production-api-key",
  "watch_folder": "/absolute/path/to/watch_folder",
  "scan_interval_seconds": 3600,
  "file_extensions": [".txt", ".json", ".log"],
  "max_file_size_mb": 10,
  "enable_logging": true,
  "log_file": "/absolute/path/to/logs/autopost_status.jsonl"
}
```

**Best Practices:**
- Use absolute paths for production
- Set appropriate scan intervals
- Enable logging for troubleshooting
- Rotate logs periodically
- Monitor disk space

### Security Considerations

**File Permissions:**

```bash
# Restrict config.json permissions
chmod 600 config.json

# Ensure logs directory is writable
chmod 755 logs

# Set appropriate ownership (Linux)
sudo chown autopost:autopost config.json
sudo chown autopost:autopost -R logs/
```

**Service User (Linux):**

Create a dedicated service user:

```bash
# Create system user
sudo useradd -r -s /bin/false autopost

# Set ownership
sudo chown -R autopost:autopost /opt/pulse-registry-system

# Update service file
sudo nano /etc/systemd/system/sr-autopost.service
# Ensure: User=autopost and Group=autopost
```

## Monitoring and Maintenance

### Health Checks

Set up periodic health checks:

**Cron-based Health Check:**

```bash
# Add to crontab
0 */6 * * * /path/to/pulse-registry-system/scripts/heartbeat.py --json >> /var/log/sr-autopost-health.log 2>&1
```

**Monitoring Script:**

Create a monitoring script that alerts on failures:

```bash
#!/bin/bash
# monitor.sh

cd /path/to/pulse-registry-system

# Run health check
if python3 scripts/heartbeat.py --json > /tmp/health.json; then
    echo "Health check passed"
else
    echo "Health check FAILED"
    # Send alert (email, Slack, etc.)
    # mail -s "SR-OS AutoPost Health Check Failed" admin@example.com < /tmp/health.json
fi
```

### Log Rotation

**Linux logrotate configuration:**

```bash
sudo nano /etc/logrotate.d/sr-autopost
```

```
/opt/pulse-registry-system/logs/*.jsonl {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    missingok
    create 0644 autopost autopost
}
```

### Backup Strategy

**Critical Files:**
- `config.json` - Configuration (encrypted backup)
- `posted_files.json` - Tracking data
- `logs/autopost_status.jsonl` - Audit trail

**Automated Backup:**

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR=/backup/sr-autopost/$(date +%Y%m%d)
mkdir -p "$BACKUP_DIR"

cd /path/to/pulse-registry-system
cp config.json "$BACKUP_DIR/"
cp posted_files.json "$BACKUP_DIR/"
cp -r logs/ "$BACKUP_DIR/"

echo "Backup completed to $BACKUP_DIR"
```

## Scaling

For high-volume deployments:

1. **Multiple Instances**: Run separate instances with different watch folders
2. **Load Balancing**: Distribute files across instances
3. **Monitoring**: Use centralized log aggregation
4. **Alerting**: Set up automated alerts for failures

## Next Steps

After setting up automated deployment:

1. ✅ Verify automation is working (check logs after scheduled run)
2. ✅ Set up monitoring and alerting
3. ✅ Configure log rotation
4. ✅ Implement backup strategy
5. ✅ Document deployment-specific configurations
6. ✅ Schedule regular health checks
7. ✅ Review security settings

---

**Version:** 1.0  
**Last Updated:** 2025-11-20  
**For:** SR-OS AutoPost Remote Executor Node - Automated Deployment (Method #3)
