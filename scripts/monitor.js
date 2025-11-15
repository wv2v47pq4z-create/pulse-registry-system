/**
 * Monitoring utility for SR-OS AutoPost Remote Executor Node
 * Provides status information about contracts and pending tasks
 */

const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

// Configuration
const config = {
    rpcUrl: process.env.RPC_URL || 'http://localhost:8545',
    autoPostExecutorAddress: process.env.AUTOPOST_EXECUTOR_ADDRESS,
    pulseRegistryAddress: process.env.PULSE_REGISTRY_ADDRESS,
    zcashBridgeAddress: process.env.ZCASH_BRIDGE_ADDRESS
};

class Monitor {
    constructor(config) {
        this.config = config;
        this.provider = null;
    }

    async initialize() {
        this.provider = new ethers.JsonRpcProvider(this.config.rpcUrl);
        console.log('Connected to RPC:', this.config.rpcUrl);
    }

    /**
     * Load deployment information
     */
    loadDeployments() {
        const deploymentFile = path.join(__dirname, '..', 'config', 'deployments.json');
        
        if (!fs.existsSync(deploymentFile)) {
            console.log('No deployment file found. Please deploy contracts first.');
            return null;
        }

        return JSON.parse(fs.readFileSync(deploymentFile, 'utf8'));
    }

    /**
     * Monitor AutoPostExecutor
     */
    async monitorAutoPostExecutor() {
        if (!this.config.autoPostExecutorAddress) {
            console.log('AutoPostExecutor address not configured');
            return;
        }

        console.log('\n=== AutoPostExecutor Status ===');
        console.log('Address:', this.config.autoPostExecutorAddress);

        const deployments = this.loadDeployments();
        if (!deployments || !deployments.AutoPostExecutor) {
            console.log('Cannot load ABI');
            return;
        }

        const contract = new ethers.Contract(
            this.config.autoPostExecutorAddress,
            deployments.AutoPostExecutor.abi,
            this.provider
        );

        try {
            const taskCount = await contract.getTaskCount();
            console.log('Total tasks:', taskCount.toString());

            const pendingTasks = await contract.getPendingTasks();
            console.log('Pending tasks ready for execution:', pendingTasks.length);

            if (pendingTasks.length > 0) {
                console.log('\nPending Task IDs:');
                for (const taskId of pendingTasks) {
                    console.log(`  - ${taskId}`);
                }
            }
        } catch (error) {
            console.error('Error querying AutoPostExecutor:', error.message);
        }
    }

    /**
     * Monitor PulseRegistry
     */
    async monitorPulseRegistry() {
        if (!this.config.pulseRegistryAddress) {
            console.log('PulseRegistry address not configured');
            return;
        }

        console.log('\n=== PulseRegistry Status ===');
        console.log('Address:', this.config.pulseRegistryAddress);

        const deployments = this.loadDeployments();
        if (!deployments || !deployments.PulseRegistry) {
            console.log('Cannot load ABI');
            return;
        }

        const contract = new ethers.Contract(
            this.config.pulseRegistryAddress,
            deployments.PulseRegistry.abi,
            this.provider
        );

        try {
            const nodeCount = await contract.getNodeCount();
            console.log('Registered nodes:', nodeCount.toString());

            // Try to get info about first few nodes
            if (nodeCount > 0) {
                console.log('\nRegistered Nodes:');
                const maxToShow = Math.min(Number(nodeCount), 5);
                
                for (let i = 0; i < maxToShow; i++) {
                    try {
                        const nodeId = await contract.registeredNodes(i);
                        const [owner, endpoint, registeredAt, active] = await contract.getNode(nodeId);
                        
                        console.log(`\n  Node ID: ${nodeId}`);
                        console.log(`    Owner: ${owner}`);
                        console.log(`    Endpoint: ${endpoint}`);
                        console.log(`    Active: ${active}`);
                        console.log(`    Registered: ${new Date(Number(registeredAt) * 1000).toISOString()}`);
                    } catch (error) {
                        // Skip if we can't read this node
                    }
                }
                
                if (nodeCount > maxToShow) {
                    console.log(`\n  ... and ${Number(nodeCount) - maxToShow} more`);
                }
            }
        } catch (error) {
            console.error('Error querying PulseRegistry:', error.message);
        }
    }

    /**
     * Monitor ZcashBridge
     */
    async monitorZcashBridge() {
        if (!this.config.zcashBridgeAddress) {
            console.log('ZcashBridge address not configured');
            return;
        }

        console.log('\n=== ZcashBridge Status ===');
        console.log('Address:', this.config.zcashBridgeAddress);

        const deployments = this.loadDeployments();
        if (!deployments || !deployments.ZcashBridge) {
            console.log('Cannot load ABI');
            return;
        }

        const contract = new ethers.Contract(
            this.config.zcashBridgeAddress,
            deployments.ZcashBridge.abi,
            this.provider
        );

        try {
            const txCount = await contract.getTransactionCount();
            console.log('Total bridge transactions:', txCount.toString());

            const bridgeFee = await contract.bridgeFee();
            console.log('Bridge fee:', `${bridgeFee.toString()} basis points (${Number(bridgeFee) / 100}%)`);

            const balance = await this.provider.getBalance(this.config.zcashBridgeAddress);
            console.log('Contract balance:', ethers.formatEther(balance), 'ETH');
        } catch (error) {
            console.error('Error querying ZcashBridge:', error.message);
        }
    }

    /**
     * Monitor network status
     */
    async monitorNetwork() {
        console.log('\n=== Network Status ===');

        try {
            const blockNumber = await this.provider.getBlockNumber();
            console.log('Current block:', blockNumber);

            const network = await this.provider.getNetwork();
            console.log('Chain ID:', network.chainId.toString());

            const gasPrice = await this.provider.getFeeData();
            console.log('Gas price:', ethers.formatUnits(gasPrice.gasPrice, 'gwei'), 'gwei');
        } catch (error) {
            console.error('Error querying network:', error.message);
        }
    }

    /**
     * Run all monitors
     */
    async monitorAll() {
        await this.monitorNetwork();
        await this.monitorAutoPostExecutor();
        await this.monitorPulseRegistry();
        await this.monitorZcashBridge();
    }
}

// Main execution
async function main() {
    const monitor = new Monitor(config);
    
    try {
        await monitor.initialize();
        await monitor.monitorAll();
        
        console.log('\n=== Monitoring Complete ===\n');
        process.exit(0);
    } catch (error) {
        console.error('Monitoring failed:', error);
        process.exit(1);
    }
}

// Run if this is the main module
if (require.main === module) {
    main();
}

module.exports = Monitor;
