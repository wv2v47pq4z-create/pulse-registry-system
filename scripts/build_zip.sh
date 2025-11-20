#!/bin/bash
# SR-OS AutoPost Remote Executor Node - Build Deployment Package (Linux/macOS)
# Creates a ZIP file with all necessary files for deployment

set -e

cd "$(dirname "$0")/.."

PACKAGE_NAME="sr-autopost-deploy.zip"
BUILD_DIR="/tmp/sr-autopost-build-$$"

echo "SR-OS AutoPost Deployment Package Builder"
echo "=========================================="
echo ""

# Create build directory
echo "Creating build directory..."
mkdir -p "$BUILD_DIR"

# Copy necessary files
echo "Copying files..."
cp autopost_client.py "$BUILD_DIR/"
cp config.example.json "$BUILD_DIR/"
cp posted_files.json "$BUILD_DIR/"
cp requirements.txt "$BUILD_DIR/"
cp README.md "$BUILD_DIR/"
cp CONTRIBUTING.md "$BUILD_DIR/"
cp MASTER_PROMPT.md "$BUILD_DIR/"
cp COPILOT_AUTOPOST_AGENT.md "$BUILD_DIR/"
cp LICENSE "$BUILD_DIR/" 2>/dev/null || echo "No LICENSE file"

# Copy directories
echo "Copying directories..."
cp -r deploy "$BUILD_DIR/"
cp -r scripts "$BUILD_DIR/"
cp -r tests "$BUILD_DIR/" 2>/dev/null || echo "No tests directory"

# Create logs directory
mkdir -p "$BUILD_DIR/logs"
touch "$BUILD_DIR/logs/autopost_status.jsonl"

# Create .github directory for workflows
mkdir -p "$BUILD_DIR/.github/workflows"
cp -r .github/workflows/* "$BUILD_DIR/.github/workflows/" 2>/dev/null || echo "No workflows"

# Create ZIP
echo "Creating ZIP archive..."
cd "$BUILD_DIR"
zip -r "$PACKAGE_NAME" . -x "*.pyc" "__pycache__/*" ".DS_Store" > /dev/null

# Move to project root
mv "$PACKAGE_NAME" "$OLDPWD/"

# Clean up
cd "$OLDPWD"
rm -rf "$BUILD_DIR"

echo ""
echo "✓ Package created: $PACKAGE_NAME"
echo ""

# Show package contents
echo "Package contents:"
unzip -l "$PACKAGE_NAME" | head -20
echo "..."
echo ""

# Show package size
PACKAGE_SIZE=$(du -h "$PACKAGE_NAME" | cut -f1)
echo "Package size: $PACKAGE_SIZE"
echo ""
echo "Done!"
