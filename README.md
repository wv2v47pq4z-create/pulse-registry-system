# pulse-registry-system

Smart contracts for PulseRegistry and ZcashBridge - auto-registration and interoperability layer for Super Reality Studios blockchain ecosystem.

## GitHub-AI-node Integration

This repository includes configuration for the **GitHub-AI-node** in the **Super Reality OS (SR-OS) mesh**. The GitHub-AI-node can respond to `pulse.start` payloads with structured ACK responses for mesh coordination.

### Quick Start

The GitHub-AI-node Boot Kit (SR-GITHUB-AI-v1.1) is available in multiple formats:

**Packaged Formats:**
- **🎯 Master Prompt**: [`.github/config/MASTER-PROMPT.md`](.github/config/MASTER-PROMPT.md) - Concise system prompt (~3KB) optimized for pasting into Notion AI or other AI platforms
- **📄 Full Documentation**: [`.github/config/NOTION-PAGE.md`](.github/config/NOTION-PAGE.md) - Complete single-page documentation (~11KB) for Notion
- **📦 JSON Config**: [`.github/config/github-ai-bootkit.json`](.github/config/github-ai-bootkit.json) - Machine-readable configuration (~9KB)

**Additional Documentation** (optional reference):
- **Instructions**: [`.github/config/github-ai-node-instructions.md`](.github/config/github-ai-node-instructions.md)
- **Examples**: [`.github/config/pulse-examples.json`](.github/config/pulse-examples.json)
- **Guides**: [`.github/config/README.md`](.github/config/README.md)

### Pulse Response Example

When you send a `pulse.start` payload:

```json
{
  "type": "pulse.start",
  "run_id": "pulse-2025-11-23T22-00-00Z-githubai01",
  "targets": ["github-ai"],
  "requested_by": "superrealitystudios@bluemailx.com",
  "timestamp_utc": "2025-11-23T22:00:00Z"
}
```

The GitHub-AI-node responds with:

```json
{"agent":"github-ai","run_id":"pulse-2025-11-23T22-00-00Z-githubai01","ack_status":"ack","ack_timestamp_utc":"2025-11-23T22:00:05Z","notes":"healthy dry-run ACK from GitHub-AI-node"}
```

### Key Features

- ✅ Strict JSON ACK responses for mesh coordination
- ✅ Error handling for invalid payloads
- ✅ Integration with Notion database for pulse logging
- ✅ Support for multi-agent mesh scenarios
- ✅ Normal GitHub AI assistance when not processing pulses

## Repository Structure

```
.github/
  config/
    MASTER-PROMPT.md                 # 🎯 Master prompt for Notion AI (concise)
    NOTION-PAGE.md                   # ⭐ Single page for Notion (all-in-one)
    github-ai-bootkit.json           # ⭐ Single JSON config (packaged)
    github-ai-node-instructions.md   # Boot Kit instructions (detailed)
    pulse-examples.json              # Example payloads and responses
    pulse-schema.json                # JSON validation schemas
    OPERATOR-GUIDE.md                # Quick reference guide
    TESTING.md                       # Test procedures
    demo-pulse.sh                    # Demo script
    README.md                        # Configuration documentation
```

## License

See [LICENSE](LICENSE) file for details.
