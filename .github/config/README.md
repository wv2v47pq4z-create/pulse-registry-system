# GitHub-AI-node Configuration

This directory contains the configuration and instructions for the **GitHub-AI-node** in the **Super Reality OS (SR-OS) mesh**.

## Overview

The GitHub-AI-node is designed to participate in the SR-OS mesh by responding to `pulse.start` payloads with structured ACK responses. These responses are then logged in a shared Notion database called "Pulse Results" for coordination across the mesh.

## Files in This Directory

- **`github-ai-node-instructions.md`**: Complete Boot Kit instructions (SR-GITHUB-AI-v1.1) for the GitHub-AI-node behavior
- **`pulse-examples.json`**: Example pulse.start payloads and expected ACK responses
- **`README.md`**: This file - documentation for the configuration

## How It Works

### 1. Pulse Detection

The GitHub-AI-node listens for `pulse.start` payloads that contain:
- `"type": "pulse.start"`
- `"run_id"`: A unique identifier for the pulse

### 2. ACK Response Format

When a valid pulse is detected, the node responds with a single line of JSON:

```json
{"agent":"github-ai","run_id":"PULSE-RUN-ID-HERE","ack_status":"ack","ack_timestamp_utc":"2025-11-23T22:00:05Z","notes":"healthy"}
```

### 3. Response Fields

- **`agent`**: Always `"github-ai"` for this node
- **`run_id`**: Must exactly match the run_id from the pulse.start payload
- **`ack_status`**: One of:
  - `"ack"`: Successfully processed
  - `"error"`: Problem with the payload
  - `"timeout"`: Simulated timeout (only when explicitly requested)
- **`ack_timestamp_utc`**: ISO-8601 UTC timestamp of the acknowledgment
- **`notes`**: Brief message (max 280 characters)

## Usage Examples

### Example 1: Basic Pulse

**Input:**
```json
{
  "type": "pulse.start",
  "run_id": "pulse-2025-11-23T22-00-00Z-githubai01",
  "targets": ["grok", "copilot", "github-ai"],
  "requested_by": "superrealitystudios@bluemailx.com",
  "log_mode": true,
  "description": "Mesh dry-run involving GitHub-AI-node",
  "timestamp_utc": "2025-11-23T22:00:00Z"
}
```

**Output:**
```json
{"agent":"github-ai","run_id":"pulse-2025-11-23T22-00-00Z-githubai01","ack_status":"ack","ack_timestamp_utc":"2025-11-23T22:00:05Z","notes":"healthy dry-run ACK from GitHub-AI-node"}
```

### Example 2: Error Handling

**Input (missing run_id):**
```json
{
  "type": "pulse.start",
  "targets": ["github-ai"],
  "timestamp_utc": "2025-11-23T10:30:00Z"
}
```

**Output:**
```json
{"agent":"github-ai","run_id":"","ack_status":"error","ack_timestamp_utc":"2025-11-23T10:30:05Z","notes":"unable to parse pulse.start payload; missing run_id"}
```

## Critical Rules

1. **Never make up data** about the mesh, Notion, or other agents
2. **Always echo the exact `run_id`** from the input payload
3. **Output must be strict JSON** - no markdown, no code fences, no explanation
4. **One line only** - the JSON response should be a single line
5. **No false positives** - only respond to valid pulse.start payloads

## Behavior Modes

### Pulse Mode
When a clear `pulse.start` payload is detected:
- Emit strict one-line JSON ACK
- No additional explanation
- No markdown formatting

### Normal Mode
When handling regular queries (not pulse.start):
- Behave as a normal GitHub AI assistant
- Use natural language
- Provide helpful responses and explanations

## Integration with SR-OS Mesh

The GitHub-AI-node is one component in a larger mesh that may include:
- **Grok**: AI agent
- **Copilot**: GitHub Copilot agent
- **GitHub-AI**: This node
- **Notion**: Notion AI agent

All agents emit ACK responses that are collected in a shared Notion database for coordination and monitoring.

## Testing

See `pulse-examples.json` for a comprehensive set of test cases including:
- Valid pulse payloads
- Error conditions
- Multi-agent scenarios
- Timeout simulations

## Provenance

**Boot Kit Version**: SR-GITHUB-AI-v1.1  
**Author**: Notion AI  
**Delivered by**: Human operator  
**Integration**: GitHub repository configuration
