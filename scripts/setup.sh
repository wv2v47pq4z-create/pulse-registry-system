#!/bin/bash
# Setup script for SR-HYBRID System

set -e

echo "=== SR-HYBRID System Setup ==="

# Check Python version
echo "Checking Python version..."
python3 --version

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Install dev dependencies for development
if [ "$1" == "--dev" ]; then
    echo "Installing development dependencies..."
    pip install -r requirements-dev.txt
fi

# Create necessary directories
echo "Creating directories..."
mkdir -p data logs

# Copy environment file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env file from example..."
    cp .env.example .env
    echo "Please edit .env file with your configuration"
fi

echo "=== Setup complete! ==="
echo ""
echo "To activate the virtual environment, run:"
echo "  source venv/bin/activate"
echo ""
echo "To run the application, use:"
echo "  ./scripts/run.sh"
echo ""
echo "To run tests, use:"
echo "  pytest tests/"
