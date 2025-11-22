# Deployment Guide - Pulse Registry System

This guide provides step-by-step instructions for deploying and testing the Pulse Registry System contracts on EVM-compatible chains like InkChain.

## Table of Contents

1. [Quick Start with Remix](#quick-start-with-remix)
2. [ResonanceRegistry Deployment](#resonanceregistry-deployment)
3. [PulseEscrowPool Deployment](#pulseescrowpool-deployment)
4. [Testing Scenarios](#testing-scenarios)
5. [Production Checklist](#production-checklist)

---

## Quick Start with Remix

### Step 1: Set Up Remix Workspace

1. Navigate to [Remix IDE](https://remix.ethereum.org)
2. Create a new workspace or use the default
3. Create a `contracts` folder
4. Copy all `.sol` files from this repository into the workspace:
   - `ResonanceTypes.sol`
   - `IResonanceRegistry.sol`
   - `ResonanceRegistry.sol`
   - `ResonanceDeployer.sol`
   - `ResonanceGateExample.sol`
   - `PulseEscrowPool.sol`

### Step 2: Configure Compiler

1. Go to the "Solidity Compiler" tab (📝 icon)
2. Select compiler version: `0.8.21+commit.d9974bed`
3. Enable "Auto compile" (recommended)
4. Enable optimization: 200 runs (optional but recommended)

### Step 3: Choose Network

**For Testing:**
- Use "Remix VM (Shanghai)" - No gas costs, instant transactions
- Multiple test accounts available with 100 ETH each

**For Production:**
- Use "Injected Provider - MetaMask"
- Connect to InkChain or your target EVM network
- Ensure you have sufficient gas tokens

---

## ResonanceRegistry Deployment

### Deployment Steps

1. **Compile the contract:**
   - Open `ResonanceRegistry.sol`
   - Ensure compilation succeeds (green checkmark)

2. **Deploy:**
   - Go to "Deploy & Run Transactions" tab (🚀 icon)
   - Select `ResonanceRegistry` from contract dropdown
   - Enter constructor parameter:
     - `_integrityFloor`: e.g., `500` (represents 0.500 threshold)
   - Click "Deploy"
   - Confirm transaction in MetaMask (if using Injected Provider)

3. **Save the contract address:**
   - Copy the deployed contract address from the transaction log
   - You'll need this for integration

### Initial Configuration

#### 1. Set Up Oracles

```javascript
// From owner account
setOracle(oracleAddress)
```

Example addresses for testing:
- Oracle 1: `0x5B38Da6a701c568545dCfcB03FcB875f56beddC4`
- Oracle 2: `0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2`

#### 2. Verify Oracle Status

```javascript
oracles(oracleAddress) // Should return: true
```

#### 3. Set Initial Resonance Scores

Switch to oracle account in Remix:
```javascript
// From oracle account
setResonance(userAddress, 750) // Set 0.750 resonance
```

### Testing Checklist

- [ ] Deploy with valid integrity floor (0-1000)
- [ ] Verify owner address is correct
- [ ] Add at least one oracle
- [ ] Oracle can set resonance scores
- [ ] Non-oracle cannot set resonance (should revert)
- [ ] Read resonance with `getResonance()`
- [ ] Test `meetsIntegrityFloor()` with various scores
- [ ] Test `meetsResonanceFloor()` with custom thresholds
- [ ] Transfer ownership (optional)

---

## PulseEscrowPool Deployment

### Prerequisites

You need a deployed ERC20 token contract that implements:
- `transferFrom(address from, address to, uint256 amount)`
- `transfer(address to, uint256 amount)`

For testing, you can deploy a simple mock token.

### Deployment Steps

1. **Compile the contract:**
   - Open `PulseEscrowPool.sol`
   - Ensure compilation succeeds

2. **Deploy:**
   - Select `PulseEscrowPool` from contract dropdown
   - Enter constructor parameter:
     - `pulseTokenAddress`: Address of your PULSE token contract
   - Click "Deploy"

3. **Save the contract address**

### Initial Configuration

#### 1. Set Resolver (Optional)

```javascript
// From owner account
setResolver(resolverAddress)
```

The resolver can help finalize disputes or auto-release funds.

#### 2. Approve Token Spending

Before creating tasks, clients must approve the escrow:

```javascript
// From client account, on PULSE token contract
approve(escrowAddress, amount)
```

### Task Lifecycle Example

#### Create a Task

```javascript
// From client account (must have approved tokens first)
createTask(workerAddress, 1000) // Returns taskId
```

#### Release Payments

```javascript
// From client or resolver account
releasePayment(taskId, 300) // Release 300 tokens to worker
```

#### Check Remaining Budget

```javascript
remainingBudget(taskId) // View function
```

#### Close Task

```javascript
// From client or resolver account
closeTask(taskId) // Refunds remaining budget to client
```

### Testing Checklist

- [ ] Deploy with valid PULSE token address
- [ ] Verify owner and resolver addresses
- [ ] Client approves escrow to spend tokens
- [ ] Create task with valid worker and budget
- [ ] Verify task details with `tasks(taskId)`
- [ ] Release partial payment to worker
- [ ] Check remaining budget
- [ ] Release more payments
- [ ] Close task and verify refund
- [ ] Try operations from unauthorized accounts (should revert)

---

## Testing Scenarios

### Scenario 1: Resonance-Gated Access

**Objective:** Use ResonanceRegistry to gate access to a function.

1. Deploy `ResonanceRegistry` with integrity floor 500
2. Deploy `ResonanceGateExample` with registry address
3. Set up oracle and assign resonance scores:
   - User A: 750 (high resonance)
   - User B: 300 (low resonance)
4. Test `joinIfResonant(500)`:
   - User A: Should succeed ✓
   - User B: Should revert with "Resonance too low" ✗
5. Verify with `hasJoined(address)`

### Scenario 2: Multi-Milestone Task

**Objective:** Manage a task with multiple payment milestones.

1. Deploy `PulseEscrowPool` and mock PULSE token
2. Mint 10,000 tokens to client
3. Client approves 10,000 tokens to escrow
4. Client creates task with 10,000 budget
5. Release payments for milestones:
   - Milestone 1 (30%): Release 3,000 tokens
   - Milestone 2 (40%): Release 4,000 tokens
   - Milestone 3 (30%): Release 3,000 tokens
6. Verify worker receives all payments
7. Close task (0 remaining)

### Scenario 3: Task Cancellation

**Objective:** Close a task early and refund unused budget.

1. Create task with 5,000 budget
2. Release 2,000 to worker
3. Close task
4. Verify 3,000 refunded to client

### Scenario 4: Combined System

**Objective:** Use both contracts together.

1. Deploy both contracts
2. Only allow high-resonance workers in escrow
3. Create custom contract that checks:
   - `registry.meetsIntegrityFloor(worker)` before calling
   - `escrow.createTask(worker, budget)`

---

## Production Checklist

Before deploying to mainnet:

### Security Review

- [ ] Audit all access control modifiers
- [ ] Verify input validation on all functions
- [ ] Test edge cases (zero addresses, max values)
- [ ] Review event emissions for monitoring
- [ ] Check for reentrancy vulnerabilities (none expected)
- [ ] Verify no unchecked external calls

### Gas Optimization

- [ ] Test gas costs for common operations
- [ ] Consider batch operations for multiple updates
- [ ] Optimize storage layout if needed

### Deployment

- [ ] Use a dedicated deployer account
- [ ] Verify constructor parameters
- [ ] Document all deployed addresses
- [ ] Verify contract source code on block explorer
- [ ] Test all functions on testnet first

### Monitoring

- [ ] Set up event listeners for critical events
- [ ] Monitor oracle activity
- [ ] Track escrow balances
- [ ] Set up alerts for anomalies

### Documentation

- [ ] Document all oracle addresses
- [ ] Record governance procedures
- [ ] Create runbooks for common operations
- [ ] Share integration guides with partners

---

## Common Issues and Solutions

### Issue: "transferFrom failed" in PulseEscrowPool

**Solution:** Client must approve escrow contract first:
```javascript
pulseToken.approve(escrowAddress, amount)
```

### Issue: "caller is not an oracle"

**Solution:** Set oracle address first from owner account:
```javascript
registry.setOracle(oracleAddress)
```

### Issue: "score exceeds maximum"

**Solution:** Resonance scores must be 0-1000. Convert percentages:
- 75% = 750
- 100% = 1000

### Issue: "exceeds remaining" in releasePayment

**Solution:** Check remaining budget:
```javascript
remainingBudget(taskId)
```

---

## Support and Resources

- **GitHub:** [wv2v47pq4z-create/pulse-registry-system](https://github.com/wv2v47pq4z-create/pulse-registry-system)
- **Remix IDE:** [remix.ethereum.org](https://remix.ethereum.org)
- **Solidity Docs:** [docs.soliditylang.org](https://docs.soliditylang.org)

---

## License

MIT License - See LICENSE file for details
