# SR-OS AutoPost Remote Executor Node - Setup Guide

## Overview

The SR-OS AutoPost Remote Executor Node is an automated system for managing and executing blockchain transactions in the Super Reality Studios ecosystem. It consists of three main smart contracts and an executor node service.

## Components

### Smart Contracts

1. **PulseRegistry** - Registry for managing nodes and entities in the network
2. **ZcashBridge** - Bridge for cross-chain interoperability with Zcash
3. **AutoPostExecutor** - Automated task scheduler and executor

### Executor Node

A Node.js service that:
- Monitors pending tasks in the AutoPostExecutor contract
- Executes tasks automatically when they're ready
- Processes bridge transactions
- Registers itself in the PulseRegistry

## Installation

### Prerequisites

- Node.js v16 or higher
- npm or yarn
- Access to an Ethereum-compatible blockchain network

### Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd pulse-registry-system
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and set:
   - `RPC_URL`: Your blockchain RPC endpoint
   - `PRIVATE_KEY`: Private key for deployment and execution (keep secure!)
   - Other configuration as needed

4. **Deploy contracts**
   ```bash
   npm run deploy
   ```
   
   This will:
   - Compile all smart contracts
   - Deploy them to the configured network
   - Save deployment addresses to `config/deployments.json` and `.env.deployed`

5. **Update environment with deployed addresses**
   
   Copy the contract addresses from `.env.deployed` to your `.env` file:
   ```bash
   cat .env.deployed >> .env
   ```

6. **Start the executor node**
   ```bash
   npm start
   ```

## Usage

### Creating Automated Tasks

To create a task that will be automatically executed:

```javascript
const { ethers } = require('ethers');

// Connect to contract
const autoPostExecutor = new ethers.Contract(
    AUTOPOST_EXECUTOR_ADDRESS,
    AutoPostExecutorABI,
    wallet
);

// Create a task
const targetContract = '0x...'; // Contract to call
const callData = '0x...'; // Encoded function call
const executionTime = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
const gasLimit = 300000;
const description = 'My automated task';

const tx = await autoPostExecutor.createTask(
    targetContract,
    callData,
    executionTime,
    gasLimit,
    description
);

await tx.wait();
```

### Registering a Node

Nodes can register themselves in the PulseRegistry:

```javascript
const pulseRegistry = new ethers.Contract(
    PULSE_REGISTRY_ADDRESS,
    PulseRegistryABI,
    wallet
);

const tx = await pulseRegistry.registerNode(
    'my-node-id',
    'http://my-node-endpoint:3000'
);

await tx.wait();
```

### Using the Zcash Bridge

To bridge assets to Zcash:

```javascript
const zcashBridge = new ethers.Contract(
    ZCASH_BRIDGE_ADDRESS,
    ZcashBridgeABI,
    wallet
);

const tx = await zcashBridge.initiateBridge(
    'z1234...', // Zcash address
    { value: ethers.parseEther('1.0') } // Amount to bridge
);

await tx.wait();
```

## Architecture

### Contract Interaction Flow

```
User → AutoPostExecutor.createTask()
         ↓
Executor Node monitors pending tasks
         ↓
Executor Node → AutoPostExecutor.executeTask()
         ↓
Target Contract is called
```

### Security Considerations

1. **Private Key Management**: Store private keys securely, never commit to version control
2. **Executor Authorization**: Only authorized addresses can execute tasks
3. **Gas Limits**: Tasks have configurable gas limits to prevent excessive consumption
4. **Minimum Delay**: Tasks have a minimum execution delay for safety

## Configuration Reference

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `RPC_URL` | Blockchain RPC endpoint | http://localhost:8545 |
| `PRIVATE_KEY` | Private key for transactions | (required) |
| `PULSE_REGISTRY_ADDRESS` | PulseRegistry contract address | (from deployment) |
| `ZCASH_BRIDGE_ADDRESS` | ZcashBridge contract address | (from deployment) |
| `AUTOPOST_EXECUTOR_ADDRESS` | AutoPostExecutor contract address | (from deployment) |
| `NODE_ID` | Unique identifier for this node | executor-{timestamp} |
| `PORT` | HTTP port for node API | 3000 |
| `POLL_INTERVAL` | Task polling interval (ms) | 30000 |
| `GAS_LIMIT` | Default gas limit for transactions | 3000000 |

## Troubleshooting

### Common Issues

**"Insufficient funds"**
- Ensure the wallet has enough ETH for gas fees

**"Contract not deployed"**
- Run `npm run deploy` first
- Verify contract addresses in `.env`

**"Execution time not reached"**
- Tasks can only be executed after their scheduled time

**"Only executors can call this function"**
- The wallet must be added as an authorized executor in the contract

## Development

### Running Tests

```bash
npm test
```

### Contract Compilation

Contracts are automatically compiled during deployment. To compile manually:

```bash
npm run deploy -- --compile-only
```

## Support

For issues and questions, please open an issue in the repository.

## License

MIT License - see LICENSE file for details
