# Quick Reference - Pulse Registry System

## Contract Addresses (Update after deployment)

```
ResonanceRegistry:    0x...
PulseEscrowPool:      0x...
PULSE Token:          0x...
```

## ResonanceRegistry Quick Reference

### Constants
- **MAX_RESONANCE**: 1000 (represents 1.000)
- **Scale**: 0-1000 (0.000-1.000)

### Key Functions

#### Owner Functions
```solidity
setOracle(address oracle)           // Add oracle
removeOracle(address oracle)        // Remove oracle
setIntegrityFloor(uint32 newFloor) // Update global threshold
transferOwnership(address newOwner) // Transfer ownership
```

#### Oracle Functions
```solidity
setResonance(address entity, uint32 score) // Set resonance (0-1000)
```

#### View Functions
```solidity
getResonance(address entity) → uint32
getResonanceData(address entity) → (uint32 score, uint64 lastUpdated)
meetsResonanceFloor(address entity, uint32 floor) → bool
meetsIntegrityFloor(address entity) → bool
```

### Events
```solidity
event OracleSet(address indexed oracle)
event OracleRemoved(address indexed oracle)
event IntegrityFloorUpdated(uint32 newFloor)
event ResonanceSet(address indexed entity, uint32 score, address indexed oracle)
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```

---

## PulseEscrowPool Quick Reference

### Task Structure
```solidity
struct Task {
    address client;   // Who funded the task
    address worker;   // Who gets paid
    uint256 budget;   // Total escrowed
    uint256 paidOut;  // Already paid
    bool active;      // Task status
}
```

### Key Functions

#### Owner Functions
```solidity
setResolver(address newResolver)    // Set dispute resolver
transferOwnership(address newOwner) // Transfer ownership
```

#### Client Functions
```solidity
createTask(address worker, uint256 budget) → uint256 taskId
releasePayment(uint256 taskId, uint256 amount)
closeTask(uint256 taskId)
```

#### Resolver Functions
```solidity
releasePayment(uint256 taskId, uint256 amount)
closeTask(uint256 taskId)
```

#### View Functions
```solidity
tasks(uint256 taskId) → (client, worker, budget, paidOut, active)
remainingBudget(uint256 taskId) → uint256
```

### Events
```solidity
event TaskCreated(uint256 indexed taskId, address indexed client, address indexed worker, uint256 budget)
event TaskPaymentReleased(uint256 indexed taskId, address indexed to, uint256 amount, uint256 totalPaidOut)
event TaskClosed(uint256 indexed taskId, uint256 remainingRefunded)
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
event ResolverUpdated(address indexed newResolver)
```

---

## Common Patterns

### Pattern 1: Set Up Resonance System

```solidity
// 1. Deploy
ResonanceRegistry registry = new ResonanceRegistry(500); // 0.500 floor

// 2. Add oracle
registry.setOracle(oracleAddress);

// 3. Oracle sets scores (switch to oracle account)
registry.setResonance(user1, 750); // 0.750
registry.setResonance(user2, 300); // 0.300

// 4. Check thresholds
bool highEnough = registry.meetsIntegrityFloor(user1); // true
bool tooLow = registry.meetsIntegrityFloor(user2);     // false
```

### Pattern 2: Create and Complete Task

```solidity
// 1. Deploy escrow
PulseEscrowPool escrow = new PulseEscrowPool(pulseTokenAddress);

// 2. Approve tokens (on PULSE token contract)
pulse.approve(address(escrow), 1000);

// 3. Create task
uint256 taskId = escrow.createTask(workerAddress, 1000);

// 4. Release payments as work progresses
escrow.releasePayment(taskId, 400); // 40% done
escrow.releasePayment(taskId, 600); // 100% done

// 5. Close task (no refund needed since fully paid)
escrow.closeTask(taskId);
```

### Pattern 3: Gated Access with Resonance

```solidity
contract MyContract {
    IResonanceRegistry public registry;
    
    constructor(address _registry) {
        registry = IResonanceRegistry(_registry);
    }
    
    function privilegedAction() external {
        require(
            registry.meetsIntegrityFloor(msg.sender),
            "Insufficient resonance"
        );
        // ... perform action
    }
}
```

### Pattern 4: Task with Escrow + Resonance Gate

```solidity
function createVerifiedTask(address worker, uint256 budget) external {
    // Only allow tasks for workers with high resonance
    require(
        registry.meetsResonanceFloor(worker, 700),
        "Worker resonance too low"
    );
    
    // Approve and create task
    pulse.approve(address(escrow), budget);
    uint256 taskId = escrow.createTask(worker, budget);
    
    emit VerifiedTaskCreated(taskId, worker, budget);
}
```

---

## Error Messages Reference

### ResonanceRegistry Errors
- `"ResonanceRegistry: caller is not the owner"`
- `"ResonanceRegistry: caller is not an oracle"`
- `"ResonanceRegistry: new owner is zero address"`
- `"ResonanceRegistry: oracle is zero address"`
- `"ResonanceRegistry: oracle already set"`
- `"ResonanceRegistry: oracle not found"`
- `"ResonanceRegistry: floor exceeds maximum"`
- `"ResonanceRegistry: entity is zero address"`
- `"ResonanceRegistry: score exceeds maximum"`

### PulseEscrowPool Errors
- `"ESCROW: not owner"`
- `"ESCROW: not client/resolver"`
- `"ESCROW: pulse zero"`
- `"ESCROW: owner zero"`
- `"ESCROW: task not found"`
- `"ESCROW: worker zero"`
- `"ESCROW: budget zero"`
- `"ESCROW: transferFrom failed"`
- `"ESCROW: inactive"`
- `"ESCROW: amount zero"`
- `"ESCROW: exceeds remaining"`
- `"ESCROW: transfer failed"`
- `"ESCROW: already closed"`
- `"ESCROW: refund failed"`

### ResonanceGateExample Errors
- `"ResonanceGateExample: registry is zero address"`
- `"ResonanceGateExample: Resonance too low"`
- `"ResonanceGateExample: Already joined"`

---

## Gas Estimates (Approximate)

### ResonanceRegistry
- Deploy: ~1,100,000 gas
- setOracle: ~50,000 gas
- setResonance: ~50,000 gas (first time), ~30,000 gas (update)
- getResonance: ~2,500 gas (view)
- meetsResonanceFloor: ~3,000 gas (view)

### PulseEscrowPool
- Deploy: ~1,400,000 gas
- createTask: ~150,000 gas (includes transferFrom)
- releasePayment: ~80,000 gas (includes transfer)
- closeTask: ~60,000 gas (with refund)

*Note: Gas costs vary based on network conditions and optimization settings*

---

## Testing Quick Commands

### Remix VM Testing
```javascript
// Get test accounts
const accounts = await web3.eth.getAccounts();
const owner = accounts[0];
const oracle = accounts[1];
const user = accounts[2];

// Deploy registry
const registry = await ResonanceRegistry.new(500, {from: owner});

// Set oracle
await registry.setOracle(oracle, {from: owner});

// Set resonance
await registry.setResonance(user, 750, {from: oracle});

// Check resonance
const score = await registry.getResonance(user);
console.log("Score:", score.toString()); // 750
```

---

## Integration Checklist

- [ ] Deploy contracts to target network
- [ ] Verify source code on block explorer
- [ ] Set up oracles for ResonanceRegistry
- [ ] Configure resolver for PulseEscrowPool (if needed)
- [ ] Test with small amounts first
- [ ] Set up event monitoring
- [ ] Document contract addresses
- [ ] Create frontend integration (if applicable)
- [ ] Test access control thoroughly
- [ ] Set up backup oracles/resolvers

---

## Support

For issues or questions:
- Check DEPLOYMENT_GUIDE.md for detailed instructions
- Review contract comments and NatSpec documentation
- Verify you're using Solidity ^0.8.21
- Ensure proper access control (owner/oracle/client roles)
