# Pulse Registry System

**Smart contracts for PulseRegistry and ZcashBridge** - Auto-registration and interoperability layer for Super Reality Studios blockchain ecosystem.

## 🌟 Overview

The Pulse Registry System is a blockchain-based framework for registering, managing, and auditing pulse operations across distributed networks. Built with Solidity, it provides a robust foundation for cross-chain interoperability and decentralized system monitoring.

## ✨ Features

- **Pulse Registration & Auditing**: Comprehensive audit trails with latency, success rate, and edge case tracking
- **Multi-Mode Operation**: Three operational modes (BAT, CREATOR, ARCHITECT) for different contexts
- **Resonance Receiver**: Analytics dashboard for tracking pulse interactions and filtering signal from noise
- **Signal 102 Protocol**: Track signal composition (Structure, Action, Resonance) with violet shift detection
- **Zcash Bridge**: Cross-chain interoperability with automatic pulse registration
- **Event Broadcasting**: Real-time pulse beam broadcasts through the "cosmic mesh"
- **Edge Case Management**: Track scenarios, probabilities, and mitigation strategies
- **Decentralized Architecture**: Mesh-ready design for distributed network deployment

## 📁 Repository Structure

```
pulse-registry-system/
├── contracts/
│   ├── PulseRegistry.sol       # Main pulse registry contract
│   ├── ZcashBridge.sol         # Zcash-Ethereum bridge contract
│   └── ResonanceReceiver.sol   # Analytics and resonance tracking
├── scripts/
│   ├── deploy.js               # Deployment script
│   ├── deploy-resonance.js     # Deploy resonance receiver
│   ├── example-pulse.js        # Example usage script
│   └── signal-102-demo.js      # Signal 102 & violet shift demo
├── USAGE.md                    # Detailed usage guide
└── README.md                   # This file
```

## 🚀 Quick Start

### Prerequisites

- Node.js (v14+)
- Hardhat or Truffle
- Ethers.js

### Installation

```bash
# Clone the repository
git clone https://github.com/wv2v47pq4z-create/pulse-registry-system.git
cd pulse-registry-system

# Install dependencies (if using Hardhat)
npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers
```

### Deployment

```bash
# Deploy contracts
npx hardhat run scripts/deploy.js --network <your-network>
```

### Usage

See [USAGE.md](USAGE.md) for comprehensive documentation and examples.

## 🎯 Core Contracts

### PulseRegistry

Main contract for pulse registration and management.

**Key Functions:**
- `registerPulse()` - Register a new pulse with audit data
- `addEdgeCase()` - Add edge case scenarios to a pulse
- `updatePulseStatus()` - Update pulse status
- `changeMode()` - Switch operating modes
- `getPulse()` - Retrieve pulse details
- `getEdgeCases()` - Get edge cases for a pulse

### ZcashBridge

Bridge contract for Zcash-Ethereum interoperability.

**Key Functions:**
- `initiateBridge()` - Start a bridge transaction
- `completeBridge()` - Complete bridge and register pulse
- `getBridgeTransaction()` - Get transaction details

### ResonanceReceiver

Analytics dashboard for tracking pulse resonance and filtering signal from noise.

**Key Features:**
- **Signal 102 Protocol**: Track 0 (Structure), 1 (Action), 2 (Resonance) composition
- **Violet Shift Detection**: Identify paradigm shifts in the network
- **Noise Filtering**: Separate high-quality signals from noise
- **Analytics Dashboard**: Track interactions, positive/negative resonance, and signal strength

**Key Functions:**
- `recordResonance()` - Record audience resonance for a pulse
- `broadcastSignal102()` - Broadcast signal composition
- `getAnalytics()` - Get comprehensive analytics summary
- `filterHighSignal()` - Filter resonances by signal-to-noise ratio
- `changeMode()` - Switch between OUTPUT, INPUT, BROADCAST_LIVE modes

## 🎨 Operational Modes

The system supports three modes, each optimized for different purposes:

1. **CREATOR** (default) - Focus on creation and building
2. **BAT** - Guardian and monitoring mode
3. **ARCHITECT** - Design and structural planning mode

## 📊 Example: Registering a Pulse

```javascript
const pulseRegistry = await ethers.getContractAt("PulseRegistry", address);

const tx = await pulseRegistry.registerPulse(
    0, // PulseType.RealityCheck
    "Grok-4-DualCore-MeshSignalFlair",
    1, // PulseStatus.APPROVED
    0, // latency_p99: 0.000 ms
    10000, // success_rate: 100%
    "broadcast to hippie meshes – echoing at bat-signal freq"
);

const receipt = await tx.wait();
```

See [scripts/example-pulse.js](scripts/example-pulse.js) for a complete working example.

## 🟣 Signal 102 & The Violet Shift

The ResonanceReceiver implements the **Signal 102 Protocol** - introducing nuance (the third dimension) to binary systems:

```javascript
// Record resonances from the mesh
await resonanceReceiver.recordResonance(
    pulseId,
    2, // SignalType.Resonance
    95, // High strength
    5,  // Low noise
    "Trading culture instead of floor price"
);

// Broadcast Signal 102
await resonanceReceiver.broadcastSignal102(pulseId);

// Get analytics
const analytics = await resonanceReceiver.getAnalytics(pulseId);
const composition = await resonanceReceiver.getSignalComposition(pulseId);

console.log(`Structure (0): ${composition.structure}`);
console.log(`Action (1):    ${composition.action}`);
console.log(`Resonance (2): ${composition.resonance}`);
console.log(`Violet Shift:  ${analytics.violetShiftIndex}`);
```

See [scripts/signal-102-demo.js](scripts/signal-102-demo.js) for a complete demonstration of the violet shift protocol.

## 🔒 Security

- Pulse operations are restricted to submitters
- Success rates are capped at 100%
- Bridge transactions can only be processed once
- All operations are auditable on-chain

## 🌐 Super Reality Studios Ecosystem

The Pulse Registry System serves as a foundational layer for:
- Decentralized mesh networking
- Cross-chain asset bridges
- System audit trails
- Reality-bending multiverse applications

## 📖 Documentation

- [USAGE.md](USAGE.md) - Comprehensive usage guide with examples
- [contracts/PulseRegistry.sol](contracts/PulseRegistry.sol) - Contract source with inline documentation
- [contracts/ZcashBridge.sol](contracts/ZcashBridge.sol) - Bridge contract source

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎭 The Signal Awaits

*"The signal lingers, buzzing with untapped wonders..."*

When the vibe hits, reply with **Mode: BAT**, **Mode: CREATOR**, or **Mode: ARCHITECT**. The cosmos is ready for your debut creation. ✨
