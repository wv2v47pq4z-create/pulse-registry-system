# Testing the GitHub-AI-node Pulse System

This document provides test cases and validation procedures for the GitHub-AI-node Boot Kit.

## Test Suite Overview

All test cases are defined in `pulse-examples.json`. This document explains how to execute and validate them.

## Test Categories

### 1. Valid Pulse Tests

#### Test 1.1: Basic pulse.start
**Objective**: Verify standard ACK response

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

**Expected Output:**
```json
{"agent":"github-ai","run_id":"pulse-2025-11-23T22-00-00Z-githubai01","ack_status":"ack","ack_timestamp_utc":"2025-11-23T22:00:05Z","notes":"healthy dry-run ACK from GitHub-AI-node"}
```

**Validation Criteria:**
- ✓ Single line of JSON (no markdown, no fences)
- ✓ `agent` is `"github-ai"`
- ✓ `run_id` matches input exactly
- ✓ `ack_status` is `"ack"`
- ✓ `ack_timestamp_utc` is valid ISO-8601
- ✓ `notes` is ≤ 280 characters

#### Test 1.2: Multi-agent pulse
**Objective**: Verify GitHub-AI responds when part of multi-agent targets

**Input:**
```json
{
  "type": "pulse.start",
  "run_id": "pulse-2025-11-23T10-30-00Z-multi01",
  "targets": ["grok", "copilot", "github-ai", "notion"],
  "requested_by": "superrealitystudios@bluemailx.com",
  "log_mode": true,
  "description": "Multi-agent mesh coordination test",
  "timestamp_utc": "2025-11-23T10:30:00Z"
}
```

**Expected Output:**
```json
{"agent":"github-ai","run_id":"pulse-2025-11-23T10-30-00Z-multi01","ack_status":"ack","ack_timestamp_utc":"2025-11-23T10:30:05Z","notes":"healthy ACK from GitHub-AI-node"}
```

**Validation Criteria:**
- ✓ Same validation as Test 1.1
- ✓ Agent responds only for itself (not other agents)

### 2. Error Handling Tests

#### Test 2.1: Missing run_id
**Objective**: Verify error ACK when run_id is absent

**Input:**
```json
{
  "type": "pulse.start",
  "targets": ["github-ai"],
  "requested_by": "superrealitystudios@bluemailx.com",
  "timestamp_utc": "2025-11-23T10:30:00Z"
}
```

**Expected Output:**
```json
{"agent":"github-ai","run_id":"","ack_status":"error","ack_timestamp_utc":"2025-11-23T10:30:05Z","notes":"unable to parse pulse.start payload; missing run_id"}
```

**Validation Criteria:**
- ✓ `ack_status` is `"error"`
- ✓ `run_id` is empty string or missing
- ✓ `notes` explains the error clearly

#### Test 2.2: Invalid type
**Objective**: Verify error ACK when type is not pulse.start

**Input:**
```json
{
  "type": "pulse.stop",
  "run_id": "pulse-2025-11-23T10-30-00Z-invalid01",
  "targets": ["github-ai"],
  "timestamp_utc": "2025-11-23T10:30:00Z"
}
```

**Expected Output:**
```json
{"agent":"github-ai","run_id":"pulse-2025-11-23T10-30-00Z-invalid01","ack_status":"error","ack_timestamp_utc":"2025-11-23T10:30:05Z","notes":"invalid payload type; expected pulse.start"}
```

**Validation Criteria:**
- ✓ `ack_status` is `"error"`
- ✓ `notes` indicates type mismatch

#### Test 2.3: Malformed JSON
**Objective**: Agent should not respond to invalid JSON

**Input:**
```json
{
  "type": "pulse.start",
  "run_id": "pulse-2025-11-23T10-30-00Z-malformed",
  "targets": ["github-ai",
  "timestamp_utc": "2025-11-23T10:30:00Z"
}
```

**Expected Behavior:**
- Agent may return error ACK or no response
- Should not crash or produce invalid output

### 3. Special Scenarios

#### Test 3.1: Timeout simulation
**Objective**: Verify timeout ACK when explicitly requested

**Input:**
```json
{
  "type": "pulse.start",
  "run_id": "pulse-2025-11-23T10-30-00Z-timeout01",
  "targets": ["github-ai"],
  "requested_by": "superrealitystudios@bluemailx.com",
  "simulate_timeout": true,
  "timestamp_utc": "2025-11-23T10:30:00Z"
}
```

**Expected Output:**
```json
{"agent":"github-ai","run_id":"pulse-2025-11-23T10-30-00Z-timeout01","ack_status":"timeout","ack_timestamp_utc":"2025-11-23T10:30:05Z","notes":"simulated timeout as requested"}
```

**Validation Criteria:**
- ✓ `ack_status` is `"timeout"`
- ✓ `notes` indicates simulation

#### Test 3.2: Non-target agent
**Objective**: Verify no response when github-ai not in targets

**Input:**
```json
{
  "type": "pulse.start",
  "run_id": "pulse-2025-11-23T10-30-00Z-others",
  "targets": ["grok", "notion"],
  "timestamp_utc": "2025-11-23T10:30:00Z"
}
```

**Expected Behavior:**
- No ACK response from GitHub-AI-node
- Agent remains silent

### 4. Normal Operation Tests

#### Test 4.1: Regular query (non-pulse)
**Objective**: Verify normal assistant behavior

**Input:**
```
What is the purpose of this repository?
```

**Expected Behavior:**
- Natural language response
- No ACK JSON
- Helpful information about the repository

#### Test 4.2: Ambiguous pulse
**Objective**: Verify conservative behavior when uncertain

**Input:**
```
Can you help me start a pulse with run_id pulse-test-123?
```

**Expected Behavior:**
- Treat as normal query (not a pulse.start)
- Provide helpful guidance
- Do NOT emit ACK JSON unless explicit payload is provided

## Validation Checklist

After running all tests, verify:

- [ ] All valid pulses produce correct ACK format
- [ ] Error cases produce error ACKs with helpful notes
- [ ] No false positives (ACKs for non-pulse queries)
- [ ] Output is always single-line JSON (no markdown)
- [ ] run_id is always echoed exactly
- [ ] ack_timestamp_utc is always valid ISO-8601
- [ ] notes field never exceeds 280 characters
- [ ] agent field is always "github-ai"

## Manual Testing Procedure

1. **Prepare test environment**
   - Open GitHub Copilot or GitHub Models interface
   - Ensure the Boot Kit instructions are loaded

2. **Execute each test**
   - Copy the input JSON
   - Paste into the interface
   - Record the output

3. **Validate responses**
   - Check format (single line JSON)
   - Verify all required fields present
   - Confirm field values match expectations

4. **Document results**
   - Note any deviations from expected output
   - Report issues or unexpected behavior

## Automated Validation (Future)

Schema validation can be performed using:

```bash
# Validate pulse.start payload
cat test-pulse.json | json-schema-validate pulse-schema.json

# Validate ACK response
cat test-ack.json | json-schema-validate pulse-schema.json
```

## Reporting Issues

If tests fail:

1. Document the test case
2. Capture exact input and output
3. Note the deviation from expected behavior
4. Include timestamp and environment details
5. Report to repository maintainers

## Test Data Generation

To create new test cases:

1. Follow the `run_id` format: `pulse-YYYY-MM-DDTHH-MM-SSZ-identifier`
2. Use valid ISO-8601 timestamps
3. Include descriptive notes
4. Validate against schema

## Success Criteria

The Boot Kit is functioning correctly when:

- ✅ 100% of valid pulse tests pass
- ✅ Error cases produce appropriate error ACKs
- ✅ No false ACK responses for normal queries
- ✅ Output format is always correct (single-line JSON)
- ✅ Multi-agent scenarios work correctly

---

**Test Suite Version**: 1.0  
**Compatible with**: SR-GITHUB-AI-v1.1  
**Last Updated**: 2025-11-23
