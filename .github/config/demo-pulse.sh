#!/bin/bash
# Demo script for GitHub-AI-node Pulse System
# This script demonstrates the expected behavior of the pulse system

set -euo pipefail

echo "============================================"
echo "GitHub-AI-node Pulse System Demo"
echo "SR-GITHUB-AI-v1.1"
echo "============================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Test 1: Valid pulse.start payload${NC}"
echo "-------------------------------------------"
echo "Input:"
cat << 'EOF'
{
  "type": "pulse.start",
  "run_id": "pulse-2025-11-23T22-00-00Z-githubai01",
  "targets": ["github-ai"],
  "requested_by": "superrealitystudios@bluemailx.com",
  "timestamp_utc": "2025-11-23T22:00:00Z"
}
EOF
echo ""
echo -e "${GREEN}Expected ACK Response:${NC}"
echo '{"agent":"github-ai","run_id":"pulse-2025-11-23T22-00-00Z-githubai01","ack_status":"ack","ack_timestamp_utc":"2025-11-23T22:00:05Z","notes":"healthy dry-run ACK from GitHub-AI-node"}'
echo ""
echo ""

echo -e "${BLUE}Test 2: Multi-agent pulse${NC}"
echo "-------------------------------------------"
echo "Input:"
cat << 'EOF'
{
  "type": "pulse.start",
  "run_id": "pulse-2025-11-23T10-30-00Z-multi01",
  "targets": ["grok", "copilot", "github-ai", "notion"],
  "requested_by": "superrealitystudios@bluemailx.com",
  "timestamp_utc": "2025-11-23T10:30:00Z"
}
EOF
echo ""
echo -e "${GREEN}Expected ACK Response:${NC}"
echo '{"agent":"github-ai","run_id":"pulse-2025-11-23T10-30-00Z-multi01","ack_status":"ack","ack_timestamp_utc":"2025-11-23T10:30:05Z","notes":"healthy ACK from GitHub-AI-node"}'
echo ""
echo ""

echo -e "${BLUE}Test 3: Error - Missing run_id${NC}"
echo "-------------------------------------------"
echo "Input:"
cat << 'EOF'
{
  "type": "pulse.start",
  "targets": ["github-ai"],
  "timestamp_utc": "2025-11-23T10:30:00Z"
}
EOF
echo ""
echo -e "${YELLOW}Expected Error ACK:${NC}"
echo '{"agent":"github-ai","run_id":"","ack_status":"error","ack_timestamp_utc":"2025-11-23T10:30:05Z","notes":"unable to parse pulse.start payload; missing run_id"}'
echo ""
echo ""

echo -e "${BLUE}Test 4: Regular query (non-pulse)${NC}"
echo "-------------------------------------------"
echo "Input:"
echo "What is this repository for?"
echo ""
echo -e "${GREEN}Expected Behavior:${NC}"
echo "Normal GitHub AI assistant response (NOT a pulse ACK)"
echo "Example: 'This repository contains smart contracts for PulseRegistry and ZcashBridge...'"
echo ""
echo ""

echo "============================================"
echo "Demo Complete!"
echo "============================================"
echo ""
echo "For full testing, see: .github/config/TESTING.md"
echo "For operator guide, see: .github/config/OPERATOR-GUIDE.md"
echo "For complete instructions, see: .github/config/github-ai-node-instructions.md"
