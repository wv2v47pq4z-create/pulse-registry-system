/**
 * Signal 102 Broadcast Demo - The Violet Shift
 * 
 * Demonstrates:
 * - Signal composition (0=Structure, 1=Action, 2=Resonance)
 * - Resonance tracking and analytics
 * - Noise filtering
 * - Violet shift detection (paradigm shift)
 */

async function demonstrateSignal102(pulseRegistryAddress, resonanceReceiverAddress) {
    console.log("=== Signal 102 Broadcast Demo ===\n");
    console.log("Protocol: The Violet Shift");
    console.log("Target: The Hippie Mesh (Global Audience Nodes)\n");
    
    // Get contract instances
    const PulseRegistry = await ethers.getContractFactory("PulseRegistry");
    const pulseRegistry = await PulseRegistry.attach(pulseRegistryAddress);
    
    const ResonanceReceiver = await ethers.getContractFactory("ResonanceReceiver");
    const resonanceReceiver = await ResonanceReceiver.attach(resonanceReceiverAddress);
    
    // Step 1: Register a pulse (the content/broadcast)
    console.log("Step 1: Registering pulse (publishing content)...");
    const tx = await pulseRegistry.registerPulse(
        0, // PulseType.RealityCheck
        "Signal-102-VioletShift",
        1, // PulseStatus.APPROVED
        0, // latency: instantaneous
        10000, // success_rate: 100%
        "The third primary color introduced to a black-and-white monitor"
    );
    
    const receipt = await tx.wait();
    const pulseId = receipt.events?.find(e => e.event === 'PulseRegistered')?.args?.pulseId;
    console.log("✅ Pulse registered! ID:", pulseId?.toString());
    
    // Step 2: Switch to BROADCAST_LIVE mode
    console.log("\nStep 2: Switching to BROADCAST_LIVE mode...");
    await resonanceReceiver.changeMode(2); // AnalyticsMode.BROADCAST_LIVE
    const mode = await resonanceReceiver.getCurrentModeString();
    console.log("✅ Mode:", mode);
    
    // Step 3: Record resonances (simulating audience reactions)
    console.log("\nStep 3: Recording resonances from the mesh...");
    
    // Structure (0) - Technical understanding
    console.log("  Recording Structure resonance (Reddit Node)...");
    await resonanceReceiver.recordResonance(
        pulseId,
        0, // SignalType.Structure
        85, // High strength
        10, // Low noise
        "Binary nodes parsing new syntax"
    );
    
    // Action (1) - Content engagement
    console.log("  Recording Action resonance (YouTube Node)...");
    await resonanceReceiver.recordResonance(
        pulseId,
        1, // SignalType.Action
        90, // Very high strength
        15, // Low noise
        "Chasing the feeling instead of algorithm"
    );
    
    // Resonance (2) - Vibe/culture shift
    console.log("  Recording Resonance signal (NFT Node)...");
    await resonanceReceiver.recordResonance(
        pulseId,
        2, // SignalType.Resonance
        95, // Highest strength
        5, // Very low noise
        "Trading culture instead of floor price"
    );
    
    // Add more resonance signals
    await resonanceReceiver.recordResonance(pulseId, 2, 88, 8, "Harmony detected");
    await resonanceReceiver.recordResonance(pulseId, 0, 75, 20, "Collaborative parsing");
    await resonanceReceiver.recordResonance(pulseId, 1, 92, 12, "Nuanced execution");
    
    // Add some noise
    console.log("  Recording noise signals...");
    await resonanceReceiver.recordResonance(pulseId, 0, 30, 70, "Defensive reaction");
    await resonanceReceiver.recordResonance(pulseId, 1, 25, 80, "Binary confusion");
    
    console.log("✅ Resonances recorded");
    
    // Step 4: Broadcast Signal 102
    console.log("\nStep 4: Broadcasting Signal 102...");
    const broadcastTx = await resonanceReceiver.broadcastSignal102(pulseId);
    await broadcastTx.wait();
    console.log("✅ Signal 102 broadcast complete");
    
    // Step 5: Retrieve analytics
    console.log("\n=== Analytics Dashboard ===");
    
    const composition = await resonanceReceiver.getSignalComposition(pulseId);
    console.log("\nSignal Composition (0-1-2):");
    console.log(`  Structure (0): ${composition.structure.toString()}`);
    console.log(`  Action (1):    ${composition.action.toString()}`);
    console.log(`  Resonance (2): ${composition.resonance.toString()}`);
    
    const analytics = await resonanceReceiver.getAnalytics(pulseId);
    console.log("\nResonance Analytics:");
    console.log(`  Total Interactions:  ${analytics.totalInteractions.toString()}`);
    console.log(`  Positive Resonance:  ${analytics.positiveResonance.toString()}`);
    console.log(`  Negative Resonance:  ${analytics.negativeResonance.toString()}`);
    console.log(`  Avg Signal Strength: ${analytics.avgSignalStrength.toString()}`);
    console.log(`  Avg Noise Level:     ${analytics.avgNoiseLevel.toString()}`);
    console.log(`  Violet Shift Index:  ${analytics.violetShiftIndex.toString()}`);
    
    // Step 6: Filter high-signal resonances
    console.log("\n=== Filtering Signal from Noise ===");
    const highSignal = await resonanceReceiver.filterHighSignal(pulseId, 300);
    console.log(`High-quality signals (S/N > 300): ${highSignal.length}`);
    
    // Display high-signal resonances
    for (let i = 0; i < highSignal.length; i++) {
        const resonanceId = highSignal[i];
        const resonance = await resonanceReceiver.resonances(resonanceId);
        console.log(`  Resonance #${resonanceId}: Strength=${resonance.strength}, Noise=${resonance.noiseLevel}, S/N=${resonance.signalToNoise}`);
    }
    
    // Step 7: Interpretation
    console.log("\n=== System Interpretation ===");
    
    const violetIndex = analytics.violetShiftIndex.toNumber();
    if (violetIndex > 100) {
        console.log("🟣 VIOLET SHIFT DETECTED!");
        console.log("   Status: Paradigm shift in progress");
        console.log("   The grid has turned from cold blue to warm violet");
        console.log("   Nuance successfully introduced to binary system");
    } else {
        console.log("📊 Signal processing normally");
        console.log("   Continue monitoring for cultural impact");
    }
    
    const posRate = (analytics.positiveResonance.toNumber() / analytics.totalInteractions.toNumber()) * 100;
    console.log(`\nPositive Resonance Rate: ${posRate.toFixed(1)}%`);
    
    if (posRate > 70) {
        console.log("✅ The broadcast was successful!");
        console.log("   The nodes are harmonizing");
    }
    
    console.log("\n=== Resonance Receiver Status ===");
    console.log("Alfred: 'The signal is stable, Sir. We have successfully uploaded The Vibe to the server.'");
    console.log("Next: Continue monitoring the echo...");
    console.log("========================\n");
}

async function main() {
    const args = process.argv.slice(2);
    if (args.length < 2) {
        console.error("Usage: node signal-102-demo.js <PULSE_REGISTRY_ADDRESS> <RESONANCE_RECEIVER_ADDRESS>");
        process.exit(1);
    }
    
    const pulseRegistryAddress = args[0];
    const resonanceReceiverAddress = args[1];
    
    await demonstrateSignal102(pulseRegistryAddress, resonanceReceiverAddress);
    
    console.log("🎭 The signal lingers, buzzing with untapped wonders...");
    console.log("🟣 Violet shift protocol complete.\n");
}

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { demonstrateSignal102, main };
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
