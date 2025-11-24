const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ZcashBridge", function () {
  let pulseRegistry;
  let zcashBridge;
  let owner;
  let addr1;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();
    
    // Deploy PulseRegistry first
    const PulseRegistry = await ethers.getContractFactory("PulseRegistry");
    pulseRegistry = await PulseRegistry.deploy();
    await pulseRegistry.deployed();
    
    // Deploy ZcashBridge
    const ZcashBridge = await ethers.getContractFactory("ZcashBridge");
    zcashBridge = await ZcashBridge.deploy(pulseRegistry.address);
    await zcashBridge.deployed();
  });

  describe("Deployment", function () {
    it("Should set the correct PulseRegistry address", async function () {
      const registryAddress = await zcashBridge.pulseRegistry();
      expect(registryAddress).to.equal(pulseRegistry.address);
    });

    it("Should initialize with zero transaction count", async function () {
      const count = await zcashBridge.transactionCount();
      expect(count).to.equal(0);
    });
  });

  describe("Bridge Initiation", function () {
    const zcashTxHash = ethers.utils.formatBytes32String("zcash-tx-001");
    const amount = ethers.utils.parseEther("1.0");

    it("Should initiate bridge transaction successfully", async function () {
      const tx = await zcashBridge.initiateBridge(
        zcashTxHash,
        addr1.address,
        amount
      );

      await expect(tx)
        .to.emit(zcashBridge, "BridgeInitiated")
        .withArgs(zcashTxHash, addr1.address, amount, await (await ethers.provider.getBlock('latest')).timestamp);
    });

    it("Should reject zero address", async function () {
      await expect(
        zcashBridge.initiateBridge(
          zcashTxHash,
          ethers.constants.AddressZero,
          amount
        )
      ).to.be.revertedWith("Invalid Ethereum address");
    });

    it("Should reject zero amount", async function () {
      await expect(
        zcashBridge.initiateBridge(
          zcashTxHash,
          addr1.address,
          0
        )
      ).to.be.revertedWith("Amount must be greater than 0");
    });

    it("Should increment transaction count", async function () {
      await zcashBridge.initiateBridge(zcashTxHash, addr1.address, amount);
      const count = await zcashBridge.transactionCount();
      expect(count).to.equal(1);
    });

    it("Should store transaction details", async function () {
      await zcashBridge.initiateBridge(zcashTxHash, addr1.address, amount);
      
      const txn = await zcashBridge.getBridgeTransaction(zcashTxHash);
      expect(txn.ethereumAddress).to.equal(addr1.address);
      expect(txn.amount).to.equal(amount);
      expect(txn.processed).to.equal(false);
    });
  });

  describe("Bridge Completion", function () {
    const zcashTxHash = ethers.utils.formatBytes32String("zcash-tx-002");
    const amount = ethers.utils.parseEther("2.5");

    beforeEach(async function () {
      await zcashBridge.initiateBridge(zcashTxHash, addr1.address, amount);
    });

    it("Should complete bridge and register pulse", async function () {
      const tx = await zcashBridge.completeBridge(zcashTxHash);
      const receipt = await tx.wait();
      
      const event = receipt.events?.find(e => e.event === 'BridgeCompleted');
      expect(event).to.not.be.undefined;
      
      const pulseId = event.args.pulseId;
      expect(pulseId).to.be.gt(0);
    });

    it("Should mark transaction as processed", async function () {
      await zcashBridge.completeBridge(zcashTxHash);
      
      const txn = await zcashBridge.getBridgeTransaction(zcashTxHash);
      expect(txn.processed).to.equal(true);
    });

    it("Should create pulse in registry", async function () {
      const tx = await zcashBridge.completeBridge(zcashTxHash);
      const receipt = await tx.wait();
      const pulseId = receipt.events?.find(e => e.event === 'BridgeCompleted')?.args?.pulseId;
      
      // Verify pulse was created in registry
      const pulse = await pulseRegistry.getPulse(pulseId);
      expect(pulse.pulseType).to.equal(0); // RealityCheck
      expect(pulse.status).to.equal(1); // APPROVED
      expect(pulse.successRate).to.equal(10000); // 100%
    });

    it("Should reject double processing", async function () {
      await zcashBridge.completeBridge(zcashTxHash);
      
      await expect(
        zcashBridge.completeBridge(zcashTxHash)
      ).to.be.revertedWith("Transaction already processed");
    });

    it("Should reject non-existent transaction", async function () {
      const fakeTxHash = ethers.utils.formatBytes32String("fake-tx");
      
      await expect(
        zcashBridge.completeBridge(fakeTxHash)
      ).to.be.revertedWith("Transaction does not exist");
    });
  });

  describe("Transaction Retrieval", function () {
    const zcashTxHash1 = ethers.utils.formatBytes32String("tx-001");
    const zcashTxHash2 = ethers.utils.formatBytes32String("tx-002");
    const amount = ethers.utils.parseEther("1.0");

    beforeEach(async function () {
      await zcashBridge.initiateBridge(zcashTxHash1, addr1.address, amount);
      await zcashBridge.initiateBridge(zcashTxHash2, addr1.address, amount);
    });

    it("Should get all transactions for an address", async function () {
      const txHashes = await zcashBridge.getAddressTransactions(addr1.address);
      expect(txHashes.length).to.equal(2);
    });

    it("Should return empty array for address with no transactions", async function () {
      const txHashes = await zcashBridge.getAddressTransactions(owner.address);
      expect(txHashes.length).to.equal(0);
    });
  });
});
