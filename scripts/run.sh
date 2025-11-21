#!/bin/bash
# Run script for SR-HYBRID System

set -e

# Load environment variables if .env exists
if [ -f ".env" ]; then
    echo "Loading environment variables from .env..."
    export $(cat .env | grep -v '^#' | xargs)
fi

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Set default values
export SR_HOST=${SR_HOST:-0.0.0.0}
export SR_PORT=${SR_PORT:-8080}
export SR_LOG_LEVEL=${SR_LOG_LEVEL:-INFO}

echo "=== Starting SR-HYBRID System ==="
echo "Host: $SR_HOST"
echo "Port: $SR_PORT"
echo "Log Level: $SR_LOG_LEVEL"
echo ""

# Run the application
python -m src.sr_graph
