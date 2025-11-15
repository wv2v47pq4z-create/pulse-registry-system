/**
 * SR-OS AutoPost Remote Executor Node
 * Main entry point for the remote executor service
 */

const { ethers } = require('ethers');
const dotenv = require('dotenv');
const fs = require('fs');
const path = require('path');

// Load environment variables
dotenv.config();

// Configuration
const config = {
    rpcUrl: process.env.RPC_URL || 'http://localhost:8545',
    privateKey: process.env.PRIVATE_KEY,
    autoPostExecutorAddress: process.env.AUTOPOST_EXECUTOR_ADDRESS,
    pulseRegistryAddress: process.env.PULSE_REGISTRY_ADDRESS,
    zcashBridgeAddress: process.env.ZCASH_BRIDGE_ADDRESS,
    pollInterval: parseInt(process.env.POLL_INTERVAL) || 30000, // 30 seconds
    gasLimit: process.env.GAS_LIMIT || 3000000,
    nodeId: process.env.NODE_ID || `executor-${Date.now()}`
};

class ExecutorNode {
    constructor(config) {
        this.config = config;
        this.provider = null;
        this.wallet = null;
        this.autoPostExecutor = null;
        this.pulseRegistry = null;
        this.zcashBridge = null;
        this.isRunning = false;
    }

    /**
     * Initialize the executor node
     */
    async initialize() {
        console.log('Initializing SR-OS AutoPost Remote Executor Node...');
        console.log(`Node ID: ${this.config.nodeId}`);

        // Setup provider
        this.provider = new ethers.JsonRpcProvider(this.config.rpcUrl);
        console.log(`Connected to RPC: ${this.config.rpcUrl}`);

        // Setup wallet
        if (this.config.privateKey) {
            this.wallet = new ethers.Wallet(this.config.privateKey, this.provider);
            console.log(`Wallet address: ${this.wallet.address}`);
        } else {
            console.warn('No private key provided. Running in read-only mode.');
        }

        // Load contract ABIs
        const autoPostExecutorABI = this.loadABI('AutoPostExecutor');
        const pulseRegistryABI = this.loadABI('PulseRegistry');
        const zcashBridgeABI = this.loadABI('ZcashBridge');

        // Initialize contracts
        if (this.config.autoPostExecutorAddress) {
            this.autoPostExecutor = new ethers.Contract(
                this.config.autoPostExecutorAddress,
                autoPostExecutorABI,
                this.wallet || this.provider
            );
            console.log(`AutoPostExecutor contract loaded at ${this.config.autoPostExecutorAddress}`);
        }

        if (this.config.pulseRegistryAddress) {
            this.pulseRegistry = new ethers.Contract(
                this.config.pulseRegistryAddress,
                pulseRegistryABI,
                this.wallet || this.provider
            );
            console.log(`PulseRegistry contract loaded at ${this.config.pulseRegistryAddress}`);
        }

        if (this.config.zcashBridgeAddress) {
            this.zcashBridge = new ethers.Contract(
                this.config.zcashBridgeAddress,
                zcashBridgeABI,
                this.wallet || this.provider
            );
            console.log(`ZcashBridge contract loaded at ${this.config.zcashBridgeAddress}`);
        }

        console.log('Initialization complete.');
    }

    /**
     * Load contract ABI from compiled artifacts
     */
    loadABI(contractName) {
        // Simple ABI for demonstration - in production, load from compiled artifacts
        const abis = {
            AutoPostExecutor: [
                'function getPendingTasks() view returns (bytes32[])',
                'function executeTask(bytes32 taskId)',
                'function executeBatch(bytes32[] taskIds)',
                'function getTask(bytes32 taskId) view returns (address, address, bytes, uint256, uint256, uint8, string)',
                'event TaskExecuted(bytes32 indexed taskId, bool success, bytes returnData)',
                'event TaskFailed(bytes32 indexed taskId, string reason)'
            ],
            PulseRegistry: [
                'function registerNode(string nodeId, string endpoint)',
                'function isNodeActive(string nodeId) view returns (bool)',
                'function getNode(string nodeId) view returns (address, string, uint256, bool)',
                'event NodeRegistered(string indexed nodeId, address indexed owner, string endpoint)'
            ],
            ZcashBridge: [
                'function getTransaction(bytes32 txId) view returns (address, string, uint256, uint256, uint8)',
                'function completeBridge(bytes32 txId)',
                'function failBridge(bytes32 txId, string reason)',
                'event BridgeInitiated(bytes32 indexed txId, address indexed sender, string zcashAddress, uint256 amount)'
            ]
        };

        return abis[contractName] || [];
    }

    /**
     * Register this node in the PulseRegistry
     */
    async registerNode() {
        if (!this.pulseRegistry || !this.wallet) {
            console.log('Cannot register node: PulseRegistry or wallet not configured');
            return;
        }

        try {
            const endpoint = `http://localhost:${process.env.PORT || 3000}`;
            console.log(`Registering node ${this.config.nodeId} with endpoint ${endpoint}...`);
            
            const tx = await this.pulseRegistry.registerNode(this.config.nodeId, endpoint);
            await tx.wait();
            
            console.log(`Node registered successfully. TX: ${tx.hash}`);
        } catch (error) {
            if (error.message.includes('already registered')) {
                console.log('Node already registered.');
            } else {
                console.error('Failed to register node:', error.message);
            }
        }
    }

    /**
     * Main execution loop
     */
    async start() {
        console.log('\n=== Starting Executor Node ===\n');
        this.isRunning = true;

        // Register node if registry is configured
        if (this.pulseRegistry) {
            await this.registerNode();
        }

        // Main loop
        while (this.isRunning) {
            try {
                await this.executePendingTasks();
                await this.processBridgeTransactions();
                
                // Wait before next iteration
                await this.sleep(this.config.pollInterval);
            } catch (error) {
                console.error('Error in execution loop:', error.message);
                await this.sleep(5000); // Wait 5 seconds before retrying
            }
        }
    }

    /**
     * Execute pending tasks from AutoPostExecutor
     */
    async executePendingTasks() {
        if (!this.autoPostExecutor) {
            return;
        }

        try {
            const pendingTasks = await this.autoPostExecutor.getPendingTasks();
            
            if (pendingTasks.length === 0) {
                return;
            }

            console.log(`Found ${pendingTasks.length} pending tasks`);

            if (!this.wallet) {
                console.log('Wallet not configured. Cannot execute tasks.');
                return;
            }

            // Execute tasks in batch if possible
            if (pendingTasks.length > 1) {
                console.log('Executing batch of tasks...');
                const tx = await this.autoPostExecutor.executeBatch(pendingTasks);
                const receipt = await tx.wait();
                console.log(`Batch executed. TX: ${tx.hash}, Gas used: ${receipt.gasUsed.toString()}`);
            } else {
                // Execute single task
                console.log(`Executing task ${pendingTasks[0]}...`);
                const tx = await this.autoPostExecutor.executeTask(pendingTasks[0]);
                const receipt = await tx.wait();
                console.log(`Task executed. TX: ${tx.hash}, Gas used: ${receipt.gasUsed.toString()}`);
            }
        } catch (error) {
            console.error('Error executing pending tasks:', error.message);
        }
    }

    /**
     * Process bridge transactions
     */
    async processBridgeTransactions() {
        if (!this.zcashBridge) {
            return;
        }

        // This is a placeholder for bridge processing logic
        // In production, this would monitor bridge events and process them
        // For now, we just log that we're checking
        // console.log('Checking for bridge transactions...');
    }

    /**
     * Stop the executor node
     */
    stop() {
        console.log('Stopping executor node...');
        this.isRunning = false;
    }

    /**
     * Sleep utility
     */
    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

// Main execution
async function main() {
    const node = new ExecutorNode(config);
    
    // Handle graceful shutdown
    process.on('SIGINT', () => {
        console.log('\nReceived SIGINT signal');
        node.stop();
        process.exit(0);
    });

    process.on('SIGTERM', () => {
        console.log('\nReceived SIGTERM signal');
        node.stop();
        process.exit(0);
    });

    try {
        await node.initialize();
        await node.start();
    } catch (error) {
        console.error('Fatal error:', error);
        process.exit(1);
    }
}

// Run if this is the main module
if (require.main === module) {
    main();
}

module.exports = ExecutorNode;
