#!/bin/bash
# SR-OS AutoPost Remote Executor Node - Health Check Script
# This script performs health checks on the autopost client

set -e

# Change to script's parent directory
cd "$(dirname "$0")/.."

echo "SR-OS AutoPost Health Check"
echo "============================"
echo ""

# Check Python installation
echo -n "Python 3.10+: "
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
    echo "✓ Found Python $PYTHON_VERSION"
else
    echo "✗ Not found"
    exit 1
fi

# Check dependencies
echo -n "Dependencies: "
if python3 -c "import requests" &> /dev/null; then
    echo "✓ Installed"
else
    echo "✗ Missing"
    exit 1
fi

# Check configuration
echo -n "Configuration: "
if [ -f "config.json" ]; then
    if python3 -c "import json; json.load(open('config.json'))" &> /dev/null; then
        echo "✓ Valid"
    else
        echo "✗ Invalid JSON"
        exit 1
    fi
elif [ -f "config.example.json" ]; then
    echo "⚠ Using example config"
else
    echo "✗ Not found"
    exit 1
fi

# Check watch folder
echo -n "Watch folder: "
WATCH_FOLDER=$(python3 -c "import json; print(json.load(open('config.example.json' if not open('config.json') else 'config.json'))['watch_folder'])" 2>/dev/null || echo "./watch_folder")
if [ -d "$WATCH_FOLDER" ]; then
    FILE_COUNT=$(find "$WATCH_FOLDER" -type f 2>/dev/null | wc -l)
    echo "✓ Exists ($FILE_COUNT files)"
else
    echo "⚠ Not found"
fi

# Check logs directory
echo -n "Logs directory: "
if [ -d "logs" ]; then
    if [ -f "logs/autopost_status.jsonl" ]; then
        LOG_LINES=$(wc -l < logs/autopost_status.jsonl)
        echo "✓ Exists ($LOG_LINES log entries)"
    else
        echo "✓ Exists (no logs yet)"
    fi
else
    echo "⚠ Not found"
fi

# Check tracking file
echo -n "Tracking file: "
if [ -f "posted_files.json" ]; then
    if python3 -c "import json; json.load(open('posted_files.json'))" &> /dev/null; then
        TRACKED_COUNT=$(python3 -c "import json; print(len(json.load(open('posted_files.json'))))")
        echo "✓ Valid ($TRACKED_COUNT files tracked)"
    else
        echo "⚠ Invalid JSON"
    fi
else
    echo "⚠ Not found"
fi

# Test import
echo -n "Client import: "
if python3 -c "import autopost_client" &> /dev/null; then
    echo "✓ Success"
else
    echo "✗ Failed"
    exit 1
fi

# Run test mode
echo ""
echo "Running test mode..."
echo "--------------------"
if python3 autopost_client.py test; then
    echo ""
    echo "✓ Health check PASSED"
    exit 0
else
    echo ""
    echo "✗ Health check FAILED"
    exit 1
fi
