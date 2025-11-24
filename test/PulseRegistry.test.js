const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PulseRegistry", function () {
  let pulseRegistry;
  let owner;
  let addr1;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();
    
    const PulseRegistry = await ethers.getContractFactory("PulseRegistry");
    pulseRegistry = await PulseRegistry.deploy();
    await pulseRegistry.deployed();
  });

  describe("Deployment", function () {
    it("Should set the correct initial mode to CREATOR", async function () {
      const mode = await pulseRegistry.getCurrentModeString();
      expect(mode).to.equal("CREATOR");
    });

    it("Should initialize with zero pulse counter", async function () {
      const counter = await pulseRegistry.pulseCounter();
      expect(counter).to.equal(0);
    });
  });

  describe("Pulse Registration", function () {
    it("Should register a pulse successfully", async function () {
      const tx = await pulseRegistry.registerPulse(
        0, // PulseType.RealityCheck
        "Test-System-001",
        1, // PulseStatus.APPROVED
        0,
        10000,
        "Test resonance field"
      );

      const receipt = await tx.wait();
      const event = receipt.events?.find(e => e.event === 'PulseRegistered');
      
      expect(event).to.not.be.undefined;
      expect(event.args.systemId).to.equal("Test-System-001");
    });

    it("Should increment pulse counter after registration", async function () {
      await pulseRegistry.registerPulse(
        0,
        "System-1",
        1,
        0,
        10000,
        "Field-1"
      );

      const counter = await pulseRegistry.pulseCounter();
      expect(counter).to.equal(1);
    });

    it("Should reject success rate over 100%", async function () {
      await expect(
        pulseRegistry.registerPulse(
          0,
          "System-1",
          1,
          0,
          10001, // 100.01%
          "Field-1"
        )
      ).to.be.revertedWith("Success rate cannot exceed 100%");
    });

    it("Should store pulse details correctly", async function () {
      const tx = await pulseRegistry.registerPulse(
        0,
        "Grok-4-DualCore-MeshSignalFlair",
        1,
        0,
        10000,
        "broadcast to hippie meshes"
      );

      await tx.wait();

      const pulse = await pulseRegistry.getPulse(1);
      expect(pulse.pulseType).to.equal(0);
      expect(pulse.systemId).to.equal("Grok-4-DualCore-MeshSignalFlair");
      expect(pulse.status).to.equal(1);
      expect(pulse.latencyP99).to.equal(0);
      expect(pulse.successRate).to.equal(10000);
      expect(pulse.identityCrisis).to.equal(false);
      expect(pulse.emptyCalories).to.equal(0);
      expect(pulse.resonanceField).to.equal("broadcast to hippie meshes");
      expect(pulse.submitter).to.equal(owner.address);
    });
  });

  describe("Edge Cases", function () {
    let pulseId;

    beforeEach(async function () {
      const tx = await pulseRegistry.registerPulse(
        0,
        "Test-System",
        1,
        0,
        10000,
        "Test field"
      );
      const receipt = await tx.wait();
      pulseId = receipt.events?.find(e => e.event === 'PulseRegistered')?.args?.pulseId;
    });

    it("Should add edge case successfully", async function () {
      await pulseRegistry.addEdgeCase(
        pulseId,
        "Mesh vibe misalignment",
        "0.05%",
        "Resonance boost"
      );

      const edgeCases = await pulseRegistry.getEdgeCases(pulseId);
      expect(edgeCases.length).to.equal(1);
      expect(edgeCases[0].scenario).to.equal("Mesh vibe misalignment");
      expect(edgeCases[0].probability).to.equal("0.05%");
      expect(edgeCases[0].mitigation).to.equal("Resonance boost");
    });

    it("Should allow multiple edge cases", async function () {
      await pulseRegistry.addEdgeCase(pulseId, "Case 1", "1%", "Mit 1");
      await pulseRegistry.addEdgeCase(pulseId, "Case 2", "2%", "Mit 2");

      const edgeCases = await pulseRegistry.getEdgeCases(pulseId);
      expect(edgeCases.length).to.equal(2);
    });

    it("Should reject edge case from non-owner", async function () {
      await expect(
        pulseRegistry.connect(addr1).addEdgeCase(
          pulseId,
          "Scenario",
          "1%",
          "Mitigation"
        )
      ).to.be.revertedWith("Not authorized");
    });
  });

  describe("Mode Changes", function () {
    it("Should change mode to BAT", async function () {
      await pulseRegistry.changeMode(0); // Mode.BAT
      const mode = await pulseRegistry.getCurrentModeString();
      expect(mode).to.equal("BAT");
    });

    it("Should change mode to ARCHITECT", async function () {
      await pulseRegistry.changeMode(2); // Mode.ARCHITECT
      const mode = await pulseRegistry.getCurrentModeString();
      expect(mode).to.equal("ARCHITECT");
    });

    it("Should emit ModeChanged event", async function () {
      await expect(pulseRegistry.changeMode(0))
        .to.emit(pulseRegistry, "ModeChanged")
        .withArgs(1, 0); // From CREATOR to BAT
    });
  });

  describe("Pulse Retrieval", function () {
    it("Should get submitter pulses", async function () {
      await pulseRegistry.registerPulse(0, "S1", 1, 0, 10000, "F1");
      await pulseRegistry.registerPulse(0, "S2", 1, 0, 10000, "F2");

      const pulses = await pulseRegistry.getSubmitterPulses(owner.address);
      expect(pulses.length).to.equal(2);
    });

    it("Should revert on invalid pulse ID", async function () {
      await expect(
        pulseRegistry.getPulse(999)
      ).to.be.revertedWith("Invalid pulse ID");
    });
  });

  describe("Status Updates", function () {
    let pulseId;

    beforeEach(async function () {
      const tx = await pulseRegistry.registerPulse(
        0,
        "Test-System",
        0, // PENDING
        0,
        10000,
        "Test field"
      );
      const receipt = await tx.wait();
      pulseId = receipt.events?.find(e => e.event === 'PulseRegistered')?.args?.pulseId;
    });

    it("Should update pulse status", async function () {
      await pulseRegistry.updatePulseStatus(pulseId, 1); // APPROVED

      const pulse = await pulseRegistry.getPulse(pulseId);
      expect(pulse.status).to.equal(1);
    });

    it("Should reject status update from non-owner", async function () {
      await expect(
        pulseRegistry.connect(addr1).updatePulseStatus(pulseId, 1)
      ).to.be.revertedWith("Not authorized");
    });
  });
});
