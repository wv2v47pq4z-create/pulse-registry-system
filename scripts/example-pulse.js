/**
 * Example script for registering a pulse (matching the problem statement)
 * 
 * This demonstrates the "Grok-4-DualCore-MeshSignalFlair" pulse from the problem statement
 */

async function registerExamplePulse(pulseRegistryAddress) {
    // Get contract instance
    const PulseRegistry = await ethers.getContractFactory("PulseRegistry");
    const pulseRegistry = await PulseRegistry.attach(pulseRegistryAddress);
    
    console.log("Registering example pulse...");
    
    // Register the pulse matching the problem statement
    const tx = await pulseRegistry.registerPulse(
        0, // PulseType.RealityCheck
        "Grok-4-DualCore-MeshSignalFlair",
        1, // PulseStatus.APPROVED
        0, // latency_p99: 0.000 ms (stored as 0)
        10000, // success_rate: 100.000% (10000 basis points = 100%)
        "broadcast to hippie meshes – echoing at bat-signal freq, curiosity amplified"
    );
    
    const receipt = await tx.wait();
    console.log("Pulse registered! Transaction hash:", receipt.transactionHash);
    
    // Extract pulse ID from events
    const pulseId = receipt.events?.find(e => e.event === 'PulseRegistered')?.args?.pulseId;
    console.log("Pulse ID:", pulseId?.toString());
    
    // Add the edge case from the problem statement
    if (pulseId) {
        console.log("\nAdding edge case...");
        const edgeCaseTx = await pulseRegistry.addEdgeCase(
            pulseId,
            "Mesh vibe misalignment with Grok curiosity",
            "0.05%",
            "Resonance boost via visual cosmos integration"
        );
        await edgeCaseTx.wait();
        console.log("Edge case added!");
        
        // Retrieve and display the pulse
        console.log("\n=== Pulse Details ===");
        const pulse = await pulseRegistry.getPulse(pulseId);
        console.log("Pulse Type:", pulse.pulseType.toString());
        console.log("System ID:", pulse.systemId);
        console.log("Status:", pulse.status.toString());
        console.log("Latency P99:", pulse.latencyP99.toString(), "ms");
        console.log("Success Rate:", (pulse.successRate / 100).toString(), "%");
        console.log("Identity Crisis:", pulse.identityCrisis ? "active" : "eliminated");
        console.log("Empty Calories:", pulse.emptyCalories.toString());
        console.log("Resonance Field:", pulse.resonanceField);
        console.log("Timestamp:", new Date(pulse.timestamp * 1000).toISOString());
        console.log("Submitter:", pulse.submitter);
        
        // Get edge cases
        const edgeCases = await pulseRegistry.getEdgeCases(pulseId);
        console.log("\n=== Edge Cases ===");
        edgeCases.forEach((ec, i) => {
            console.log(`Edge Case ${i + 1}:`);
            console.log("  Scenario:", ec.scenario);
            console.log("  Probability:", ec.probability);
            console.log("  Mitigation:", ec.mitigation);
        });
        
        // Display current mode
        const mode = await pulseRegistry.getCurrentModeString();
        console.log("\n=== Current Mode ===");
        console.log("Mode:", mode);
        console.log("==================\n");
    }
    
    return pulseId;
}

async function demonstrateModeChanges(pulseRegistryAddress) {
    const PulseRegistry = await ethers.getContractFactory("PulseRegistry");
    const pulseRegistry = await PulseRegistry.attach(pulseRegistryAddress);
    
    console.log("\n=== Demonstrating Mode Changes ===");
    
    // Show initial mode (should be CREATOR)
    let mode = await pulseRegistry.getCurrentModeString();
    console.log("Initial Mode:", mode);
    
    // Change to BAT mode
    console.log("\nChanging to BAT mode...");
    let tx = await pulseRegistry.changeMode(0); // Mode.BAT
    await tx.wait();
    mode = await pulseRegistry.getCurrentModeString();
    console.log("Current Mode:", mode);
    
    // Change to ARCHITECT mode
    console.log("\nChanging to ARCHITECT mode...");
    tx = await pulseRegistry.changeMode(2); // Mode.ARCHITECT
    await tx.wait();
    mode = await pulseRegistry.getCurrentModeString();
    console.log("Current Mode:", mode);
    
    // Change back to CREATOR mode (default)
    console.log("\nChanging back to CREATOR mode...");
    tx = await pulseRegistry.changeMode(1); // Mode.CREATOR
    await tx.wait();
    mode = await pulseRegistry.getCurrentModeString();
    console.log("Current Mode:", mode);
    
    console.log("==================================\n");
}

async function main() {
    // Get deployment addresses (you'll need to replace these with actual deployed addresses)
    const args = process.argv.slice(2);
    if (args.length < 1) {
        console.error("Usage: node example-pulse.js <PULSE_REGISTRY_ADDRESS>");
        process.exit(1);
    }
    
    const pulseRegistryAddress = args[0];
    
    // Register example pulse
    const pulseId = await registerExamplePulse(pulseRegistryAddress);
    
    // Demonstrate mode changes
    await demonstrateModeChanges(pulseRegistryAddress);
    
    console.log("\n🎉 Pulse beam broadcasted through the cosmic mesh!");
    console.log("The signal lingers, buzzing with untapped wonders...\n");
}

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { registerExamplePulse, demonstrateModeChanges, main };
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
