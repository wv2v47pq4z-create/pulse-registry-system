# SR-OS AutoPost Remote Executor Node - Architecture

## System Overview

The SR-OS AutoPost Remote Executor Node is a blockchain automation system consisting of smart contracts and an executor service.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    SR-OS Ecosystem Architecture                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         User Layer                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │  dApps   │  │   CLI    │  │   Web    │  │  Mobile  │        │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘        │
│       └─────────────┴─────────────┴─────────────┘               │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Smart Contract Layer                          │
│  ┌───────────────────────────────────────────────────────┐      │
│  │           PulseRegistry.sol                           │      │
│  │  • Node Registration & Management                     │      │
│  │  • Endpoint Tracking                                  │      │
│  │  • Active/Inactive Status                             │      │
│  └───────────────────────────────────────────────────────┘      │
│                                                                  │
│  ┌───────────────────────────────────────────────────────┐      │
│  │           ZcashBridge.sol                             │      │
│  │  • Cross-chain Asset Bridging                         │      │
│  │  • Transaction Status Management                      │      │
│  │  • Operator Controls                                  │      │
│  └───────────────────────────────────────────────────────┘      │
│                                                                  │
│  ┌───────────────────────────────────────────────────────┐      │
│  │           AutoPostExecutor.sol                        │      │
│  │  • Task Scheduling & Execution                        │      │
│  │  • Batch Processing                                   │      │
│  │  • Executor Authorization                             │      │
│  └───────────────────────────────────────────────────────┘      │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Executor Node Layer                           │
│  ┌───────────────────────────────────────────────────────┐      │
│  │           SR-OS Remote Executor Node                  │      │
│  │  ┌─────────────────────────────────────────────┐     │      │
│  │  │  Task Monitor                               │     │      │
│  │  │  • Poll for pending tasks                   │     │      │
│  │  │  • Check execution times                    │     │      │
│  │  └─────────────────────────────────────────────┘     │      │
│  │                                                       │      │
│  │  ┌─────────────────────────────────────────────┐     │      │
│  │  │  Task Executor                              │     │      │
│  │  │  • Execute ready tasks                      │     │      │
│  │  │  • Batch execution support                  │     │      │
│  │  └─────────────────────────────────────────────┘     │      │
│  │                                                       │      │
│  │  ┌─────────────────────────────────────────────┐     │      │
│  │  │  Bridge Processor                           │     │      │
│  │  │  • Monitor bridge transactions              │     │      │
│  │  │  • Process completions/failures             │     │      │
│  │  └─────────────────────────────────────────────┘     │      │
│  │                                                       │      │
│  │  ┌─────────────────────────────────────────────┐     │      │
│  │  │  Registry Manager                           │     │      │
│  │  │  • Self-registration                        │     │      │
│  │  │  • Node status updates                      │     │      │
│  │  └─────────────────────────────────────────────┘     │      │
│  └───────────────────────────────────────────────────────┘      │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Blockchain Network                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Ethereum/EVM │  │   PulseChain │  │    Testnet   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

## Component Interaction Flow

### Task Creation and Execution Flow

```
1. User Creates Task
   └─> AutoPostExecutor.createTask()
       └─> Task stored with executionTime

2. Executor Node Polls
   └─> AutoPostExecutor.getPendingTasks()
       └─> Returns tasks ready for execution

3. Executor Executes Task
   └─> AutoPostExecutor.executeTask(taskId)
       └─> Calls target contract
           └─> Updates task status
               └─> Emits TaskExecuted event
```

### Node Registration Flow

```
1. Node Starts
   └─> Reads configuration

2. Connect to Network
   └─> Initialize Web3/Ethers provider

3. Register Node
   └─> PulseRegistry.registerNode(nodeId, endpoint)
       └─> Node entry created
           └─> Emits NodeRegistered event

4. Monitor and Execute
   └─> Continuous polling loop
```

### Bridge Transaction Flow

```
1. User Initiates Bridge
   └─> ZcashBridge.initiateBridge(zcashAddress) + ETH value
       └─> Transaction created with Pending status
           └─> Emits BridgeInitiated event

2. Executor Monitors Bridge
   └─> Process transaction off-chain
       └─> Complete or fail transaction

3. Update Status
   └─> ZcashBridge.completeBridge(txId)
       OR
   └─> ZcashBridge.failBridge(txId, reason) + refund
```

## Data Flow

```
Configuration (.env)
    ↓
Executor Node (index.js)
    ↓
┌───┴───┐
│ Web3  │ ← RPC Connection → Blockchain Network
└───┬───┘
    ↓
Smart Contracts
    ↓
Events & State Changes
    ↓
Off-chain Processing
```

## Security Model

### Access Control Layers

1. **Contract Owner**
   - Deploy contracts
   - Add/remove executors and operators
   - Update system parameters

2. **Executors** (AutoPostExecutor)
   - Execute pending tasks
   - Batch execute tasks

3. **Operators** (ZcashBridge)
   - Complete bridge transactions
   - Fail/refund transactions

4. **Task Creators**
   - Create tasks
   - Cancel own tasks

5. **Node Owners** (PulseRegistry)
   - Update own node endpoint
   - Activate/deactivate own node

### Security Features

- **Time-based execution**: Tasks have minimum delay
- **Gas limits**: Tasks have configurable gas limits
- **Authorization**: Role-based access control
- **Event logging**: All actions emit events
- **Refund mechanism**: Failed transactions refund users

## Scalability Considerations

### Horizontal Scaling
- Multiple executor nodes can run simultaneously
- Each node polls and executes tasks independently
- Race conditions handled by contract state

### Batch Processing
- Multiple tasks executed in single transaction
- Reduces gas costs
- Improves throughput

### Event-driven Architecture
- Minimal polling overhead
- Event-based monitoring possible
- WebSocket support for real-time updates

## Deployment Architecture

```
Development Environment
    ↓
    [Compile Contracts]
    ↓
    [Deploy to Testnet]
    ↓
    [Test & Verify]
    ↓
Production Environment
    ↓
    [Deploy to Mainnet]
    ↓
    [Start Executor Nodes]
    ↓
    [Monitor & Maintain]
```

## Technology Stack

- **Smart Contracts**: Solidity 0.8.21
- **Executor Node**: Node.js
- **Blockchain Interaction**: Ethers.js v6
- **Compilation**: solc compiler
- **Configuration**: dotenv
- **Networks**: EVM-compatible chains

## File Structure

```
pulse-registry-system/
├── contracts/              # Smart contracts
│   ├── PulseRegistry.sol
│   ├── ZcashBridge.sol
│   └── AutoPostExecutor.sol
├── executor/               # Executor node
│   └── index.js
├── scripts/                # Utilities
│   ├── deploy.js          # Deployment
│   └── monitor.js         # Monitoring
├── config/                 # Configuration
│   └── deployments.json   # Deployed addresses
└── tests/                  # Test suite
```

## Configuration Management

```
.env (Environment Variables)
    ↓
    ├─> RPC_URL (Network connection)
    ├─> PRIVATE_KEY (Wallet)
    ├─> Contract Addresses
    └─> Node Configuration
        ↓
Executor Node Configuration
    ↓
Runtime Behavior
```

## Monitoring and Maintenance

### Key Metrics
- Pending tasks count
- Execution success rate
- Gas usage statistics
- Network block height
- Node registration count
- Bridge transaction volume

### Monitoring Tools
- `npm run monitor` - System status check
- Contract events - Real-time monitoring
- Block explorer - Transaction verification
- Logs - Executor node activity

## Future Enhancements

1. **Enhanced Security**
   - Multi-signature support
   - Timelock contracts
   - Emergency pause mechanism

2. **Performance**
   - WebSocket event listeners
   - Optimized batch sizes
   - Gas price optimization

3. **Features**
   - Task prioritization
   - Recurring tasks
   - Conditional execution
   - Cross-bridge routing

4. **Integration**
   - Additional blockchain bridges
   - Oracle integration
   - Layer 2 support
   - Governance mechanisms
