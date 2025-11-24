# Pulse Registry System - Usage Guide

## Overview

The Pulse Registry System is a smart contract-based framework for registering and managing pulse audit results with blockchain-based verification. It supports three operational modes (BAT, CREATOR, ARCHITECT) and provides interoperability with Zcash through the ZcashBridge contract.

## Contracts

### PulseRegistry.sol

The main contract for managing pulse registrations with comprehensive audit trails.

**Key Features:**
- Multiple pulse types: RealityCheck, BatSignal, CreatorBeam, ArchitectBlueprint
- Pulse status management: PENDING, APPROVED, REJECTED
- Operating modes: BAT, CREATOR (default), ARCHITECT
- Edge case tracking with scenario, probability, and mitigation fields
- Complete audit trail with latency and success rate metrics

### ZcashBridge.sol

Bridge contract for Zcash-Ethereum interoperability with auto-registration.

**Key Features:**
- Bridge transactions from Zcash to Ethereum
- Automatic pulse registration for completed bridges
- Transaction tracking and verification

## Core Concepts

### PulseAuditResult

Each registered pulse contains:
- `pulse_type`: Type of pulse (RealityCheck, BatSignal, etc.)
- `system_id`: Unique system identifier
- `status`: Current status (PENDING, APPROVED, REJECTED)
- `latency_p99`: 99th percentile latency in microseconds
- `success_rate`: Success rate in basis points (10000 = 100%)
- `known_edge_cases`: Array of edge cases with scenarios, probabilities, and mitigations
- `identity_crisis`: Boolean flag (eliminated = false)
- `empty_calories`: Counter for empty/invalid operations
- `resonance_field`: Metadata describing the pulse's broadcast characteristics
- `timestamp`: Block timestamp of registration
- `submitter`: Address of the pulse submitter

### Modes

The system operates in three modes:

1. **CREATOR** (default): Focus on creation and building
2. **BAT**: Guardian/monitoring mode
3. **ARCHITECT**: Design and structural mode

Modes can be changed using the `changeMode()` function.

## Usage Examples

### Deploying Contracts

```javascript
// Using Hardhat or similar framework
const { deployPulseRegistry, deployZcashBridge } = require('./scripts/deploy.js');

async function deploy() {
    const pulseRegistry = await deployPulseRegistry();
    const zcashBridge = await deployZcashBridge(pulseRegistry.address);
    
    console.log("PulseRegistry:", pulseRegistry.address);
    console.log("ZcashBridge:", zcashBridge.address);
}
```

### Registering a Pulse

```javascript
const pulseRegistry = await ethers.getContractAt("PulseRegistry", PULSE_REGISTRY_ADDRESS);

// Register a pulse
const tx = await pulseRegistry.registerPulse(
    0, // PulseType.RealityCheck
    "Grok-4-DualCore-MeshSignalFlair", // system_id
    1, // PulseStatus.APPROVED
    0, // latency_p99 (0.000 ms)
    10000, // success_rate (100%)
    "broadcast to hippie meshes – echoing at bat-signal freq, curiosity amplified" // resonance_field
);

const receipt = await tx.wait();
const pulseId = receipt.events?.find(e => e.event === 'PulseRegistered')?.args?.pulseId;
```

### Adding Edge Cases

```javascript
await pulseRegistry.addEdgeCase(
    pulseId,
    "Mesh vibe misalignment with Grok curiosity", // scenario
    "0.05%", // probability
    "Resonance boost via visual cosmos integration" // mitigation
);
```

### Retrieving Pulse Data

```javascript
// Get pulse details
const pulse = await pulseRegistry.getPulse(pulseId);
console.log("System ID:", pulse.systemId);
console.log("Status:", pulse.status);
console.log("Success Rate:", pulse.successRate / 100, "%");

// Get edge cases
const edgeCases = await pulseRegistry.getEdgeCases(pulseId);
edgeCases.forEach(ec => {
    console.log("Scenario:", ec.scenario);
    console.log("Probability:", ec.probability);
    console.log("Mitigation:", ec.mitigation);
});
```

### Changing Modes

```javascript
// Change to BAT mode
await pulseRegistry.changeMode(0); // Mode.BAT

// Change to CREATOR mode
await pulseRegistry.changeMode(1); // Mode.CREATOR

// Change to ARCHITECT mode
await pulseRegistry.changeMode(2); // Mode.ARCHITECT

// Check current mode
const mode = await pulseRegistry.getCurrentModeString();
console.log("Current Mode:", mode);
```

### Using the Zcash Bridge

```javascript
const zcashBridge = await ethers.getContractAt("ZcashBridge", ZCASH_BRIDGE_ADDRESS);

// Initiate bridge transaction
const zcashTxHash = "0x1234..."; // Zcash transaction hash
const ethereumAddress = "0xabcd...";
const amount = ethers.utils.parseEther("1.0");

await zcashBridge.initiateBridge(zcashTxHash, ethereumAddress, amount);

// Complete bridge and register pulse
const pulseId = await zcashBridge.completeBridge(zcashTxHash);
```

## Events

### PulseRegistry Events

- `PulseRegistered(uint256 indexed pulseId, PulseType pulseType, string systemId, PulseStatus status, address indexed submitter)`
- `PulseBeamBroadcast(uint256 indexed pulseId, string resonanceField, uint256 timestamp)`
- `ModeChanged(Mode oldMode, Mode newMode)`

### ZcashBridge Events

- `BridgeInitiated(bytes32 indexed zcashTxHash, address indexed ethereumAddress, uint256 amount, uint256 timestamp)`
- `BridgeCompleted(bytes32 indexed zcashTxHash, uint256 pulseId)`

## Running Example Scripts

### Deploy Contracts

```bash
npx hardhat run scripts/deploy.js --network <network-name>
```

### Register Example Pulse

```bash
npx hardhat run scripts/example-pulse.js --network <network-name> <PULSE_REGISTRY_ADDRESS>
```

Or with Node.js:
```bash
node scripts/example-pulse.js <PULSE_REGISTRY_ADDRESS>
```

## Security Considerations

1. Only pulse submitters can add edge cases or update status for their pulses
2. Success rate is capped at 100% (10000 basis points)
3. Bridge transactions can only be processed once
4. All operations are transparent and auditable on-chain

## Integration with Super Reality Studios Ecosystem

The Pulse Registry System is designed as a foundational layer for the Super Reality Studios blockchain ecosystem, providing:

- **Decentralized mesh-ready architecture**: Pulses can be broadcast across distributed networks
- **Interoperability**: ZcashBridge enables cross-chain communication
- **Audit trails**: Comprehensive tracking of all system operations
- **Mode flexibility**: Adapt system behavior to different operational contexts

## Support

For issues, questions, or contributions, please refer to the main repository documentation.
