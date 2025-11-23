# Operator Guide: GitHub-AI-node Pulse System

## Quick Reference

This guide helps operators interact with the GitHub-AI-node in the SR-OS mesh.

## Sending a Pulse

### Basic Pulse Command

To send a pulse to the GitHub-AI-node, provide a `pulse.start` payload:

```json
{
  "type": "pulse.start",
  "run_id": "pulse-2025-11-23T22-00-00Z-githubai01",
  "targets": ["github-ai"],
  "requested_by": "your-email@example.com",
  "log_mode": true,
  "description": "Brief description of pulse purpose",
  "timestamp_utc": "2025-11-23T22:00:00Z"
}
```

### Expected Response

The node will respond with a single line of JSON:

```json
{"agent":"github-ai","run_id":"pulse-2025-11-23T22-00-00Z-githubai01","ack_status":"ack","ack_timestamp_utc":"2025-11-23T22:00:05Z","notes":"healthy dry-run ACK from GitHub-AI-node"}
```

## Multi-Agent Coordination

### Sending to Multiple Agents

```json
{
  "type": "pulse.start",
  "run_id": "pulse-2025-11-23T10-30-00Z-multi01",
  "targets": ["grok", "copilot", "github-ai", "notion"],
  "requested_by": "your-email@example.com",
  "log_mode": true,
  "description": "Multi-agent mesh coordination test",
  "timestamp_utc": "2025-11-23T10:30:00Z"
}
```

Each agent in the targets list should respond with their own ACK.

## Understanding ACK Status

### ✅ `ack` - Success
The agent successfully received and processed the pulse.

**Example:**
```json
{"agent":"github-ai","run_id":"pulse-xxx","ack_status":"ack","ack_timestamp_utc":"2025-11-23T22:00:05Z","notes":"healthy"}
```

### ❌ `error` - Problem Detected
The agent encountered an issue with the payload.

**Common Causes:**
- Missing `run_id`
- Invalid `type` field
- Malformed JSON

**Example:**
```json
{"agent":"github-ai","run_id":"","ack_status":"error","ack_timestamp_utc":"2025-11-23T22:00:05Z","notes":"unable to parse pulse.start payload; missing run_id"}
```

### ⏱️ `timeout` - Simulated Timeout
The agent was asked to simulate a timeout scenario.

**Example:**
```json
{"agent":"github-ai","run_id":"pulse-xxx","ack_status":"timeout","ack_timestamp_utc":"2025-11-23T22:00:05Z","notes":"simulated timeout as requested"}
```

## Generating run_id Values

### Format Pattern
```
pulse-YYYY-MM-DDTHH-MM-SSZ-identifier
```

### Examples
```
pulse-2025-11-23T22-00-00Z-githubai01
pulse-2025-11-23T10-30-00Z-multi01
pulse-2025-11-23T14-45-30Z-test-abc123
```

### Best Practices
1. Use current UTC timestamp
2. Add descriptive identifier suffix
3. Ensure uniqueness across pulses
4. Keep identifiers lowercase with hyphens

## Logging to Notion

After receiving ACK responses:

1. Copy the JSON response
2. Paste into the **"Pulse Results"** Notion database
3. Ensure proper formatting is maintained
4. Tag with appropriate metadata (agent, timestamp, status)

## Troubleshooting

### No Response
- Verify the `pulse.start` payload is valid JSON
- Check that `type` is exactly `"pulse.start"`
- Ensure `run_id` is present and non-empty
- Confirm `github-ai` is in the targets list

### Error Response
- Review the `notes` field for details
- Validate payload against schema
- Check all required fields are present

### Wrong Format
- Ensure you're sending pure JSON (no markdown)
- Remove any surrounding text or explanation
- Check for typos in field names

## Testing

Use the examples in `pulse-examples.json` for testing various scenarios:

```bash
# View examples
cat .github/config/pulse-examples.json

# Test basic pulse (copy/paste the input JSON)
# Expected: Single line ACK response
```

## Advanced: Timeout Simulation

To test timeout handling, add the `simulate_timeout` flag:

```json
{
  "type": "pulse.start",
  "run_id": "pulse-2025-11-23T10-30-00Z-timeout01",
  "targets": ["github-ai"],
  "simulate_timeout": true,
  "timestamp_utc": "2025-11-23T10:30:00Z"
}
```

## Important Reminders

⚠️ **Critical Rules:**
- Never manually create fake ACKs
- Always use the exact `run_id` from your pulse
- The agent will NOT execute real external actions unless explicitly configured
- Tools are simulated for SR-OS purposes by default

## Support & Documentation

- **Full Instructions**: `github-ai-node-instructions.md`
- **Examples**: `pulse-examples.json`
- **Schema**: `pulse-schema.json`
- **Main Docs**: `README.md`

---

**Version**: SR-GITHUB-AI-v1.1  
**Last Updated**: 2025-11-23  
**Maintained by**: Super Reality Studios
