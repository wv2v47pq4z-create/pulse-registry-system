/**
 * Deployment script for ResonanceReceiver (Analytics Mode)
 * 
 * Usage: Deploy after PulseRegistry is deployed
 */

async function deployResonanceReceiver(pulseRegistryAddress) {
    console.log("Deploying ResonanceReceiver...");
    
    // Get the contract factory
    const ResonanceReceiver = await ethers.getContractFactory("ResonanceReceiver");
    
    // Deploy the contract
    const resonanceReceiver = await ResonanceReceiver.deploy(pulseRegistryAddress);
    await resonanceReceiver.deployed();
    
    console.log("ResonanceReceiver deployed to:", resonanceReceiver.address);
    
    // Verify initial state
    const currentMode = await resonanceReceiver.getCurrentModeString();
    console.log("Initial mode:", currentMode);
    
    return resonanceReceiver;
}

async function main() {
    // Get deployment addresses (you'll need to replace these with actual deployed addresses)
    const args = process.argv.slice(2);
    if (args.length < 1) {
        console.error("Usage: node deploy-resonance.js <PULSE_REGISTRY_ADDRESS>");
        process.exit(1);
    }
    
    const pulseRegistryAddress = args[0];
    
    // Deploy ResonanceReceiver
    const resonanceReceiver = await deployResonanceReceiver(pulseRegistryAddress);
    
    console.log("\n=== Deployment Summary ===");
    console.log("ResonanceReceiver:", resonanceReceiver.address);
    console.log("========================\n");
    
    console.log("🎯 Analytics Mode: Ready to receive resonance");
    console.log("📡 Listening for signals from the mesh...\n");
    
    return resonanceReceiver;
}

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { deployResonanceReceiver, main };
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
