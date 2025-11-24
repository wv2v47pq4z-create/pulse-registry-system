/**
 * Deployment script for PulseRegistry and ZcashBridge contracts
 * 
 * Usage (with ethers.js or hardhat):
 * - Deploy PulseRegistry first
 * - Deploy ZcashBridge with PulseRegistry address
 */

async function deployPulseRegistry() {
    console.log("Deploying PulseRegistry...");
    
    // Get the contract factory
    const PulseRegistry = await ethers.getContractFactory("PulseRegistry");
    
    // Deploy the contract
    const pulseRegistry = await PulseRegistry.deploy();
    await pulseRegistry.deployed();
    
    console.log("PulseRegistry deployed to:", pulseRegistry.address);
    
    return pulseRegistry;
}

async function deployZcashBridge(pulseRegistryAddress) {
    console.log("Deploying ZcashBridge...");
    
    // Get the contract factory
    const ZcashBridge = await ethers.getContractFactory("ZcashBridge");
    
    // Deploy the contract
    const zcashBridge = await ZcashBridge.deploy(pulseRegistryAddress);
    await zcashBridge.deployed();
    
    console.log("ZcashBridge deployed to:", zcashBridge.address);
    
    return zcashBridge;
}

async function main() {
    // Deploy PulseRegistry
    const pulseRegistry = await deployPulseRegistry();
    
    // Deploy ZcashBridge
    const zcashBridge = await deployZcashBridge(pulseRegistry.address);
    
    console.log("\n=== Deployment Summary ===");
    console.log("PulseRegistry:", pulseRegistry.address);
    console.log("ZcashBridge:", zcashBridge.address);
    console.log("========================\n");
    
    // Verify initial state
    const currentMode = await pulseRegistry.getCurrentModeString();
    console.log("Initial mode:", currentMode);
    
    return {
        pulseRegistry,
        zcashBridge
    };
}

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { deployPulseRegistry, deployZcashBridge, main };
}

// Run if called directly
if (require.main === module) {
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
}
