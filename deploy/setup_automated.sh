#!/bin/bash
# SR-OS AutoPost Remote Executor Node - Automated Deployment Setup
# This script sets up automated deployment for the current platform

set -e

echo "SR-OS AutoPost - Automated Deployment Setup"
echo "============================================"
echo ""

# Detect platform
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    PLATFORM="windows"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
else
    PLATFORM="linux"
fi

echo "Detected platform: $PLATFORM"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Check if config.json exists
if [ ! -f "config.json" ]; then
    echo "⚠ Configuration file not found. Creating from example..."
    cp config.example.json config.json
    echo "✓ Created config.json from config.example.json"
    echo ""
    echo "IMPORTANT: Edit config.json with your API endpoint and credentials before proceeding."
    echo ""
    read -p "Press Enter to continue after editing config.json, or Ctrl+C to cancel..."
fi

# Verify Python dependencies
echo "Checking Python dependencies..."
if ! python3 -c "import requests" &> /dev/null; then
    echo "Installing dependencies..."
    python3 -m pip install -r requirements.txt
fi
echo "✓ Dependencies verified"
echo ""

# Run test mode
echo "Testing configuration..."
echo "Note: Test may fail if using example API endpoint (api.example.com)"
if python3 autopost_client.py test; then
    echo "✓ Configuration test passed"
else
    echo "⚠ Configuration test failed (expected if using example endpoint)"
    echo ""
    echo "To use in production, update config.json with your actual API endpoint."
    echo "Continuing with setup instructions..."
fi
echo ""

# Platform-specific automated deployment setup
case $PLATFORM in
    windows)
        echo "Setting up Windows Scheduled Task..."
        echo ""
        echo "Run the following command in PowerShell as Administrator:"
        echo ""
        echo "  cd '$PROJECT_DIR'"
        echo "  .\deploy\register_task.ps1"
        echo ""
        ;;
    
    linux)
        echo "Setting up Linux systemd service..."
        echo ""
        
        # Check if systemd is available
        if command -v systemctl &> /dev/null; then
            SERVICE_FILE="$SCRIPT_DIR/sr-autopost.service"
            
            echo "To install the systemd service, run:"
            echo ""
            echo "  sudo cp '$SERVICE_FILE' /etc/systemd/system/"
            echo "  sudo systemctl daemon-reload"
            echo "  sudo systemctl enable sr-autopost.service"
            echo "  sudo systemctl start sr-autopost.service"
            echo ""
            echo "To check status:"
            echo "  sudo systemctl status sr-autopost.service"
            echo ""
            
            # Offer to do it automatically
            if [ "$EUID" -eq 0 ]; then
                read -p "Running as root. Install service now? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    cp "$SERVICE_FILE" /etc/systemd/system/
                    systemctl daemon-reload
                    systemctl enable sr-autopost.service
                    systemctl start sr-autopost.service
                    echo "✓ Service installed and started"
                    systemctl status sr-autopost.service
                fi
            fi
        else
            echo "systemd not detected. Using cron instead..."
            echo ""
            echo "Add the following to your crontab (crontab -e):"
            echo ""
            echo "  # SR-OS AutoPost - Run every hour"
            echo "  0 * * * * cd '$PROJECT_DIR' && ./deploy/run_autopost.sh >> /var/log/sr-autopost.log 2>&1"
            echo ""
        fi
        ;;
    
    macos)
        echo "Setting up macOS automated execution..."
        echo ""
        echo "Option 1: Using cron"
        echo "Add the following to your crontab (crontab -e):"
        echo ""
        echo "  # SR-OS AutoPost - Run every hour"
        echo "  0 * * * * cd '$PROJECT_DIR' && ./deploy/run_autopost.sh >> ~/sr-autopost.log 2>&1"
        echo ""
        echo "Option 2: Using launchd (recommended for macOS)"
        echo "Create a Launch Agent plist file. See Apple's documentation for details."
        echo ""
        ;;
esac

echo "============================================"
echo "Automated deployment setup instructions provided."
echo ""
echo "For manual testing, run:"
echo "  python autopost_client.py run"
echo ""
echo "For health checks, run:"
echo "  python scripts/heartbeat.py"
echo ""
