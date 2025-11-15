/**
 * Deployment script for SR-OS smart contracts
 */

const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');
const solc = require('solc');
require('dotenv').config();

// Configuration
const config = {
    rpcUrl: process.env.RPC_URL || 'http://localhost:8545',
    privateKey: process.env.PRIVATE_KEY,
    gasLimit: process.env.GAS_LIMIT || 3000000
};

class ContractDeployer {
    constructor(config) {
        this.config = config;
        this.provider = null;
        this.wallet = null;
    }

    async initialize() {
        console.log('Initializing deployer...');
        this.provider = new ethers.JsonRpcProvider(this.config.rpcUrl);
        
        if (!this.config.privateKey) {
            throw new Error('Private key not provided in environment variables');
        }
        
        this.wallet = new ethers.Wallet(this.config.privateKey, this.provider);
        console.log(`Deployer address: ${this.wallet.address}`);
        
        const balance = await this.provider.getBalance(this.wallet.address);
        console.log(`Balance: ${ethers.formatEther(balance)} ETH`);
    }

    /**
     * Compile a Solidity contract
     */
    compileContract(contractName) {
        console.log(`\nCompiling ${contractName}.sol...`);
        
        const contractPath = path.join(__dirname, '..', 'contracts', `${contractName}.sol`);
        const source = fs.readFileSync(contractPath, 'utf8');

        const input = {
            language: 'Solidity',
            sources: {
                [`${contractName}.sol`]: {
                    content: source
                }
            },
            settings: {
                outputSelection: {
                    '*': {
                        '*': ['abi', 'evm.bytecode']
                    }
                },
                optimizer: {
                    enabled: true,
                    runs: 200
                }
            }
        };

        const output = JSON.parse(solc.compile(JSON.stringify(input)));

        if (output.errors) {
            const errors = output.errors.filter(e => e.severity === 'error');
            if (errors.length > 0) {
                console.error('Compilation errors:');
                errors.forEach(error => console.error(error.formattedMessage));
                throw new Error('Contract compilation failed');
            }
            
            // Print warnings
            const warnings = output.errors.filter(e => e.severity === 'warning');
            if (warnings.length > 0) {
                console.warn('Compilation warnings:');
                warnings.forEach(warning => console.warn(warning.formattedMessage));
            }
        }

        const contract = output.contracts[`${contractName}.sol`][contractName];
        console.log(`${contractName} compiled successfully`);
        
        return {
            abi: contract.abi,
            bytecode: contract.evm.bytecode.object
        };
    }

    /**
     * Deploy a contract
     */
    async deployContract(contractName, ...args) {
        const { abi, bytecode } = this.compileContract(contractName);

        console.log(`\nDeploying ${contractName}...`);
        
        const factory = new ethers.ContractFactory(abi, bytecode, this.wallet);
        const contract = await factory.deploy(...args, {
            gasLimit: this.config.gasLimit
        });

        console.log(`Transaction hash: ${contract.deploymentTransaction().hash}`);
        console.log('Waiting for deployment confirmation...');
        
        await contract.waitForDeployment();
        const address = await contract.getAddress();
        
        console.log(`${contractName} deployed at: ${address}`);
        
        return { contract, address, abi };
    }

    /**
     * Save deployment information
     */
    saveDeployment(deployments) {
        const configDir = path.join(__dirname, '..', 'config');
        if (!fs.existsSync(configDir)) {
            fs.mkdirSync(configDir, { recursive: true });
        }

        const deploymentFile = path.join(configDir, 'deployments.json');
        fs.writeFileSync(deploymentFile, JSON.stringify(deployments, null, 2));
        console.log(`\nDeployment information saved to ${deploymentFile}`);

        // Also save to .env format
        const envFile = path.join(__dirname, '..', '.env.deployed');
        const envContent = [
            `# Deployed contract addresses`,
            `PULSE_REGISTRY_ADDRESS=${deployments.PulseRegistry.address}`,
            `ZCASH_BRIDGE_ADDRESS=${deployments.ZcashBridge.address}`,
            `AUTOPOST_EXECUTOR_ADDRESS=${deployments.AutoPostExecutor.address}`,
            `RPC_URL=${this.config.rpcUrl}`
        ].join('\n');
        
        fs.writeFileSync(envFile, envContent);
        console.log(`Environment variables saved to ${envFile}`);
    }

    /**
     * Deploy all contracts
     */
    async deployAll() {
        const deployments = {};

        try {
            // Deploy PulseRegistry
            const pulseRegistry = await this.deployContract('PulseRegistry');
            deployments.PulseRegistry = {
                address: pulseRegistry.address,
                abi: pulseRegistry.abi
            };

            // Deploy ZcashBridge
            const zcashBridge = await this.deployContract('ZcashBridge');
            deployments.ZcashBridge = {
                address: zcashBridge.address,
                abi: zcashBridge.abi
            };

            // Deploy AutoPostExecutor
            const autoPostExecutor = await this.deployContract('AutoPostExecutor');
            deployments.AutoPostExecutor = {
                address: autoPostExecutor.address,
                abi: autoPostExecutor.abi
            };

            console.log('\n=== Deployment Summary ===');
            console.log(`PulseRegistry: ${deployments.PulseRegistry.address}`);
            console.log(`ZcashBridge: ${deployments.ZcashBridge.address}`);
            console.log(`AutoPostExecutor: ${deployments.AutoPostExecutor.address}`);

            this.saveDeployment(deployments);

            return deployments;
        } catch (error) {
            console.error('Deployment failed:', error);
            throw error;
        }
    }
}

// Main execution
async function main() {
    const deployer = new ContractDeployer(config);
    
    try {
        await deployer.initialize();
        await deployer.deployAll();
        
        console.log('\nDeployment completed successfully!');
        process.exit(0);
    } catch (error) {
        console.error('Deployment failed:', error);
        process.exit(1);
    }
}

// Run if this is the main module
if (require.main === module) {
    main();
}

module.exports = ContractDeployer;
