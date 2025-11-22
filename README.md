# Pulse Registry System

Smart contracts for PulseRegistry and ZcashBridge - auto-registration and interoperability layer for Super Reality Studios blockchain ecosystem.

## Overview

This repository contains a production-ready suite of Solidity smart contracts designed for EVM-compatible chains (like InkChain):

### Core Contracts

1. **ResonanceRegistry** - A registry for tracking resonance scores (0-1000 scale) with oracle-based updates
2. **PulseEscrowPool** - Task-based escrow system for Pulse Tokens with closed-loop fund management
3. **PulseSignatureEmitter** - Canonical on-chain emitter for Super Reality Pulse signature with metadata events

### Supporting Contracts

- **IResonanceRegistry** - Interface for read-only access to resonance data
- **ResonanceTypes** - Shared type definitions for the resonance system
- **ResonanceDeployer** - Factory contract for deploying new registries
- **ResonanceGateExample** - Example consumer demonstrating resonance-gated access control

## Contract Details

### ResonanceRegistry

A registry system that tracks "resonance" scores for addresses using a 0-1000 scale (representing 0.000-1.000):

**Features:**
- Owner/oracle access control model
- Global `integrityFloor` threshold
- Event-driven updates with indexed parameters
- Gas-optimized storage layout

**Key Functions:**
- `setResonance(address, uint32)` - Oracle sets entity resonance
- `getResonance(address)` - Read resonance score
- `meetsResonanceFloor(address, uint32)` - Check against custom threshold
- `meetsIntegrityFloor(address)` - Check against global threshold

### PulseEscrowPool

Task-based escrow for Pulse Tokens with no minting - only pre-funded transfers:

**Features:**
- Client-worker task model
- Budget tracking with partial payments
- Client or resolver authorization
- Automatic refunds of unused budget

**Key Functions:**
- `createTask(address worker, uint256 budget)` - Create escrowed task
- `releasePayment(uint256 taskId, uint256 amount)` - Release funds to worker
- `closeTask(uint256 taskId)` - Close task and refund remaining budget
- `remainingBudget(uint256 taskId)` - View remaining escrow

### PulseSignatureEmitter

Canonical on-chain emitter for the Super Reality Pulse signature with standardized metadata events:

**Features:**
- Holds official Pulse signature string and its keccak256 hash
- Authorized emitters can emit standardized metadata events
- Single event stream for indexers and subgraphs
- Auditable chain-level fingerprint for SR-OS governance

**Key Functions:**
- `emitPulseMetadata(bytes32, string, string)` - Emit metadata event with context
- `setAuthorizedEmitter(address, bool)` - Authorize/deauthorize emitters
- `getSignature()` - View Pulse signature and hash

**Use Cases:**
- Mark contract actions as "Pulse-governed"
- Create unified event stream for SRPULSE activity
- Provide governance layer audit trail

## Getting Started

### Prerequisites

- Solidity ^0.8.21
- Remix IDE (recommended) or Hardhat/Foundry
- EVM-compatible wallet

### Deployment

#### Option 1: Direct Deployment (Remix)

1. Open [Remix IDE](https://remix.ethereum.org)
2. Copy contract files into Remix workspace
3. Compile with Solidity ^0.8.21
4. Deploy contracts with appropriate constructor parameters

#### Option 2: Using ResonanceDeployer

```solidity
// Deploy the factory
ResonanceDeployer deployer = new ResonanceDeployer();

// Deploy a new registry
address registry = deployer.deployResonanceRegistry(500); // 0.500 integrity floor
```

### Testing in Remix

The `ResonanceRegistry.sol` file includes a comprehensive manual test checklist in comments at the bottom. Follow these steps to verify functionality in Remix IDE.

## Usage Examples

### Resonance-Gated Access Control

```solidity
// Deploy registry with integrity floor of 500 (0.500)
ResonanceRegistry registry = new ResonanceRegistry(500);

// Set up an oracle
registry.setOracle(oracleAddress);

// Oracle sets resonance for users
registry.setResonance(userAddress, 750); // 0.750 resonance

// Deploy gate contract
ResonanceGateExample gate = new ResonanceGateExample(address(registry));

// User joins if resonance >= 500
gate.joinIfResonant(500); // Succeeds if user has 750 resonance
```

### Task Escrow Workflow

```solidity
// Deploy escrow with Pulse token
PulseEscrowPool escrow = new PulseEscrowPool(pulseTokenAddress);

// Client approves escrow to spend tokens
pulseToken.approve(address(escrow), 1000);

// Client creates task
uint256 taskId = escrow.createTask(workerAddress, 1000);

// Release partial payment (e.g., milestone completion)
escrow.releasePayment(taskId, 300);

// Release more payments as work progresses
escrow.releasePayment(taskId, 500);

// Close task and refund remaining 200 to client
escrow.closeTask(taskId);
```

## Security Considerations

- All contracts use explicit access control (owner/oracle/client/resolver)
- Input validation on all state-changing functions
- Clear revert messages for debugging
- No reentrancy risks (checks-effects-interactions pattern)
- Immutable references where appropriate
- No token minting in escrow (closed-loop model)

## License

MIT License - See LICENSE file for details

## Development

### Compiling

```bash
# Install solc
npm install -g solc@0.8.21

# Compile contracts
cd contracts
solcjs --bin --abi --optimize *.sol
```

### File Structure

```
contracts/
├── ResonanceRegistry.sol       # Core resonance tracking
├── IResonanceRegistry.sol      # Registry interface
├── ResonanceTypes.sol          # Shared type definitions
├── ResonanceDeployer.sol       # Factory for registries
├── ResonanceGateExample.sol    # Example consumer contract
├── PulseEscrowPool.sol         # Task escrow system
└── PulseSignatureEmitter.sol   # Pulse signature emitter
```
