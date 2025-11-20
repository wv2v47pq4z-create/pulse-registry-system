#!/bin/bash
# SR-OS AutoPost Remote Executor Node - Linux/macOS Launcher
# This script launches the autopost client with proper environment setup

set -e

# Change to script's parent directory
cd "$(dirname "$0")/.."

# Check Python installation
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 not found. Please install Python 3.10 or higher."
    exit 1
fi

# Check Python version
PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
REQUIRED_VERSION="3.10"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "ERROR: Python $REQUIRED_VERSION or higher is required. Found: $PYTHON_VERSION"
    exit 1
fi

# Check dependencies
if ! python3 -c "import requests" &> /dev/null; then
    echo "ERROR: Dependencies not installed. Running pip install..."
    python3 -m pip install -r requirements.txt || {
        echo "ERROR: Failed to install dependencies."
        exit 1
    }
fi

# Run the client
echo "Starting SR-OS AutoPost Client..."
python3 autopost_client.py run

exit $?
