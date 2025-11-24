const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ResonanceReceiver", function () {
  let pulseRegistry;
  let resonanceReceiver;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    
    // Deploy PulseRegistry first
    const PulseRegistry = await ethers.getContractFactory("PulseRegistry");
    pulseRegistry = await PulseRegistry.deploy();
    await pulseRegistry.deployed();
    
    // Deploy ResonanceReceiver
    const ResonanceReceiver = await ethers.getContractFactory("ResonanceReceiver");
    resonanceReceiver = await ResonanceReceiver.deploy(pulseRegistry.address);
    await resonanceReceiver.deployed();
  });

  describe("Deployment", function () {
    it("Should set the correct PulseRegistry address", async function () {
      const registryAddress = await resonanceReceiver.pulseRegistry();
      expect(registryAddress).to.equal(pulseRegistry.address);
    });

    it("Should initialize with INPUT mode", async function () {
      const mode = await resonanceReceiver.getCurrentModeString();
      expect(mode).to.equal("INPUT");
    });

    it("Should initialize with zero resonance counter", async function () {
      const counter = await resonanceReceiver.resonanceCounter();
      expect(counter).to.equal(0);
    });
  });

  describe("Resonance Recording", function () {
    let pulseId;

    beforeEach(async function () {
      // Register a pulse first
      const tx = await pulseRegistry.registerPulse(
        0, // PulseType.RealityCheck
        "Test-Signal",
        1, // PulseStatus.APPROVED
        0,
        10000,
        "Test resonance"
      );
      const receipt = await tx.wait();
      pulseId = receipt.events?.find(e => e.event === 'PulseRegistered')?.args?.pulseId;
    });

    it("Should record resonance successfully", async function () {
      const tx = await resonanceReceiver.recordResonance(
        pulseId,
        0, // SignalType.Structure
        80, // strength
        20, // noise
        "Test metadata"
      );

      await expect(tx)
        .to.emit(resonanceReceiver, "ResonanceReceived")
        .withArgs(1, pulseId, 0, 80, owner.address);
    });

    it("Should calculate signal-to-noise ratio", async function () {
      await resonanceReceiver.recordResonance(pulseId, 0, 80, 20, "Test");
      
      const resonance = await resonanceReceiver.resonances(1);
      expect(resonance.signalToNoise).to.equal(400); // (80 * 100) / 20
    });

    it("Should reject strength over 100", async function () {
      await expect(
        resonanceReceiver.recordResonance(pulseId, 0, 101, 20, "Test")
      ).to.be.revertedWith("Strength must be 0-100");
    });

    it("Should reject noise level over 100", async function () {
      await expect(
        resonanceReceiver.recordResonance(pulseId, 0, 80, 101, "Test")
      ).to.be.revertedWith("Noise level must be 0-100");
    });

    it("Should emit SignalHighlighted for high S/N ratio", async function () {
      await expect(
        resonanceReceiver.recordResonance(pulseId, 0, 90, 10, "High quality")
      ).to.emit(resonanceReceiver, "SignalHighlighted");
    });

    it("Should track multiple resonances for same pulse", async function () {
      await resonanceReceiver.recordResonance(pulseId, 0, 80, 20, "First");
      await resonanceReceiver.recordResonance(pulseId, 1, 85, 15, "Second");
      await resonanceReceiver.recordResonance(pulseId, 2, 90, 10, "Third");

      const resonances = await resonanceReceiver.getPulseResonances(pulseId);
      expect(resonances.length).to.equal(3);
    });
  });

  describe("Signal Composition", function () {
    let pulseId;

    beforeEach(async function () {
      const tx = await pulseRegistry.registerPulse(0, "Test", 1, 0, 10000, "Test");
      const receipt = await tx.wait();
      pulseId = receipt.events?.find(e => e.event === 'PulseRegistered')?.args?.pulseId;
    });

    it("Should track signal composition correctly", async function () {
      await resonanceReceiver.recordResonance(pulseId, 0, 80, 20, "Structure");
      await resonanceReceiver.recordResonance(pulseId, 0, 75, 25, "Structure 2");
      await resonanceReceiver.recordResonance(pulseId, 1, 85, 15, "Action");
      await resonanceReceiver.recordResonance(pulseId, 2, 90, 10, "Resonance");
      await resonanceReceiver.recordResonance(pulseId, 2, 88, 12, "Resonance 2");

      const composition = await resonanceReceiver.getSignalComposition(pulseId);
      expect(composition.structure).to.equal(2);
      expect(composition.action).to.equal(1);
      expect(composition.resonance).to.equal(2);
    });
  });

  describe("Signal 102 Broadcast", function () {
    let pulseId;

    beforeEach(async function () {
      const tx = await pulseRegistry.registerPulse(0, "Signal-102", 1, 0, 10000, "Test");
      const receipt = await tx.wait();
      pulseId = receipt.events?.find(e => e.event === 'PulseRegistered')?.args?.pulseId;

      // Add resonances
      await resonanceReceiver.recordResonance(pulseId, 0, 85, 10, "Structure");
      await resonanceReceiver.recordResonance(pulseId, 1, 90, 15, "Action");
      await resonanceReceiver.recordResonance(pulseId, 2, 95, 5, "Resonance");
    });

    it("Should emit Signal102Broadcast event", async function () {
      const tx = await resonanceReceiver.broadcastSignal102(pulseId);
      
      await expect(tx)
        .to.emit(resonanceReceiver, "Signal102Broadcast")
        .withArgs(pulseId, 1, 1, 1);
    });

    it("Should detect violet shift with high resonance", async function () {
      // Add more resonances to increase violet index
      await resonanceReceiver.recordResonance(pulseId, 2, 92, 8, "High resonance");
      await resonanceReceiver.recordResonance(pulseId, 2, 88, 12, "More resonance");
      
      const tx = await resonanceReceiver.broadcastSignal102(pulseId);
      
      await expect(tx)
        .to.emit(resonanceReceiver, "VioletShiftDetected");
    });
  });

  describe("Analytics", function () {
    let pulseId;

    beforeEach(async function () {
      const tx = await pulseRegistry.registerPulse(0, "Analytics-Test", 1, 0, 10000, "Test");
      const receipt = await tx.wait();
      pulseId = receipt.events?.find(e => e.event === 'PulseRegistered')?.args?.pulseId;
    });

    it("Should track total interactions", async function () {
      await resonanceReceiver.recordResonance(pulseId, 0, 80, 20, "Test 1");
      await resonanceReceiver.recordResonance(pulseId, 1, 85, 15, "Test 2");
      await resonanceReceiver.recordResonance(pulseId, 2, 90, 10, "Test 3");

      const analytics = await resonanceReceiver.getAnalytics(pulseId);
      expect(analytics.totalInteractions).to.equal(3);
    });

    it("Should count positive and negative resonance", async function () {
      await resonanceReceiver.recordResonance(pulseId, 0, 80, 20, "Positive");
      await resonanceReceiver.recordResonance(pulseId, 1, 60, 15, "Positive");
      await resonanceReceiver.recordResonance(pulseId, 2, 30, 10, "Negative");
      await resonanceReceiver.recordResonance(pulseId, 0, 40, 5, "Negative");

      const analytics = await resonanceReceiver.getAnalytics(pulseId);
      expect(analytics.positiveResonance).to.equal(2);
      expect(analytics.negativeResonance).to.equal(2);
    });

    it("Should calculate average signal strength", async function () {
      await resonanceReceiver.recordResonance(pulseId, 0, 80, 20, "Test");
      await resonanceReceiver.recordResonance(pulseId, 1, 90, 10, "Test");
      await resonanceReceiver.recordResonance(pulseId, 2, 70, 15, "Test");

      const analytics = await resonanceReceiver.getAnalytics(pulseId);
      expect(analytics.avgSignalStrength).to.equal(80); // (80 + 90 + 70) / 3
    });
  });

  describe("Noise Filtering", function () {
    let pulseId;

    beforeEach(async function () {
      const tx = await pulseRegistry.registerPulse(0, "Filter-Test", 1, 0, 10000, "Test");
      const receipt = await tx.wait();
      pulseId = receipt.events?.find(e => e.event === 'PulseRegistered')?.args?.pulseId;

      // Add mix of high and low signal resonances
      await resonanceReceiver.recordResonance(pulseId, 0, 90, 10, "High signal"); // S/N = 900
      await resonanceReceiver.recordResonance(pulseId, 1, 30, 70, "Low signal"); // S/N = 42
      await resonanceReceiver.recordResonance(pulseId, 2, 85, 15, "High signal"); // S/N = 566
      await resonanceReceiver.recordResonance(pulseId, 0, 25, 80, "Noise"); // S/N = 31
    });

    it("Should filter high-signal resonances", async function () {
      const highSignal = await resonanceReceiver.filterHighSignal(pulseId, 500);
      expect(highSignal.length).to.equal(2); // Two resonances with S/N >= 500
    });

    it("Should return all resonances with low threshold", async function () {
      const allSignal = await resonanceReceiver.filterHighSignal(pulseId, 0);
      expect(allSignal.length).to.equal(4);
    });

    it("Should return empty array with very high threshold", async function () {
      const noSignal = await resonanceReceiver.filterHighSignal(pulseId, 1000);
      expect(noSignal.length).to.equal(0);
    });
  });

  describe("Mode Changes", function () {
    it("Should change to OUTPUT mode", async function () {
      await resonanceReceiver.changeMode(0); // AnalyticsMode.OUTPUT
      const mode = await resonanceReceiver.getCurrentModeString();
      expect(mode).to.equal("OUTPUT");
    });

    it("Should change to BROADCAST_LIVE mode", async function () {
      await resonanceReceiver.changeMode(2); // AnalyticsMode.BROADCAST_LIVE
      const mode = await resonanceReceiver.getCurrentModeString();
      expect(mode).to.equal("BROADCAST_LIVE");
    });

    it("Should emit ModeChanged event", async function () {
      await expect(resonanceReceiver.changeMode(2))
        .to.emit(resonanceReceiver, "ModeChanged")
        .withArgs(1, 2); // From INPUT to BROADCAST_LIVE
    });
  });
});
