# Pulse Registry System

Smart contracts for PulseRegistry and ZcashBridge - auto-registration and interoperability layer for Super Reality Studios blockchain ecosystem.

## Overview

The Pulse Registry System is a comprehensive blockchain solution that provides:

- **PulseRegistry**: A decentralized registry for managing nodes and entities in the network
- **ZcashBridge**: Cross-chain bridge for interoperability with Zcash blockchain
- **AutoPostExecutor**: Automated task scheduling and execution system
- **SR-OS Remote Executor Node**: A Node.js service that monitors and executes scheduled tasks

## Features

### Smart Contracts

1. **PulseRegistry** (`contracts/PulseRegistry.sol`)
   - Node registration and management
   - Endpoint tracking
   - Active/inactive status management
   - Owner-based access control

2. **ZcashBridge** (`contracts/ZcashBridge.sol`)
   - Cross-chain asset bridging
   - Transaction status tracking
   - Operator management
   - Configurable bridge fees
   - Automatic refunds for failed transactions

3. **AutoPostExecutor** (`contracts/AutoPostExecutor.sol`)
   - Scheduled task execution
   - Batch processing support
   - Configurable gas limits
   - Task status tracking
   - Security delay mechanisms

### Executor Node

The SR-OS AutoPost Remote Executor Node (`executor/index.js`) is a Node.js service that:
- Automatically monitors for pending tasks
- Executes tasks at their scheduled time
- Processes bridge transactions
- Self-registers in the PulseRegistry
- Handles graceful shutdown

## Quick Start

### Prerequisites

- Node.js v16 or higher
- npm or yarn
- Access to an Ethereum-compatible blockchain network

### Installation

```bash
# Clone the repository
git clone https://github.com/wv2v47pq4z-create/pulse-registry-system
cd pulse-registry-system

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your configuration
```

### Deployment

```bash
# Deploy contracts to your network
npm run deploy
```

This will compile and deploy all contracts, then save the deployment information to:
- `config/deployments.json` - Full deployment data with ABIs
- `.env.deployed` - Environment variables for easy configuration

### Running the Executor Node

```bash
# Update your .env with deployed contract addresses
cat .env.deployed >> .env

# Start the executor node
npm start
```

## Documentation

- [Setup Guide](SETUP.md) - Detailed installation and configuration instructions
- [API Documentation](API.md) - Complete API reference for all contracts and services
- [Configuration](config/README.md) - Configuration file details

## Project Structure

```
pulse-registry-system/
├── contracts/              # Solidity smart contracts
│   ├── PulseRegistry.sol
│   ├── ZcashBridge.sol
│   └── AutoPostExecutor.sol
├── executor/               # Executor node service
│   └── index.js
├── scripts/                # Deployment and utility scripts
│   └── deploy.js
├── config/                 # Configuration files
│   └── deployments.json   # Generated after deployment
├── tests/                  # Test files (future)
├── .env.example            # Environment variable template
├── package.json            # Node.js dependencies and scripts
├── SETUP.md               # Setup guide
├── API.md                 # API documentation
└── README.md              # This file
```

## Usage Examples

### Creating an Automated Task

```javascript
const { ethers } = require('ethers');

// Create a task that executes in 1 hour
const autoPostExecutor = new ethers.Contract(address, abi, wallet);

const callData = contractInterface.encodeFunctionData('myFunction', [param1, param2]);
const executionTime = Math.floor(Date.now() / 1000) + 3600;

const tx = await autoPostExecutor.createTask(
    targetContract,
    callData,
    executionTime,
    300000,
    "Execute myFunction"
);

await tx.wait();
```

### Registering a Node

```javascript
const pulseRegistry = new ethers.Contract(address, abi, wallet);

const tx = await pulseRegistry.registerNode(
    "my-node-id",
    "http://my-node.example.com:3000"
);

await tx.wait();
```

### Bridging to Zcash

```javascript
const zcashBridge = new ethers.Contract(address, abi, wallet);

const tx = await zcashBridge.initiateBridge(
    "z1abc123...",
    { value: ethers.parseEther("1.0") }
);

await tx.wait();
```

## Development

### Building

Contracts are compiled automatically during deployment using the solc compiler.

### Testing

```bash
npm test
```

## Security Considerations

- Store private keys securely and never commit them to version control
- Use `.env` files and add them to `.gitignore`
- Only authorize trusted addresses as executors and operators
- Set appropriate gas limits for automated tasks
- Test thoroughly on testnets before mainnet deployment
- Monitor executor node health and transaction status

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For questions and support:
- Open an issue in this repository
- Check the [Setup Guide](SETUP.md) for common issues
- Review the [API Documentation](API.md) for usage details

## Acknowledgments

Developed for Super Reality Studios blockchain ecosystem.
