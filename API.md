# SR-OS AutoPost Remote Executor Node - API Documentation

## Smart Contract APIs

### PulseRegistry

Registry contract for managing nodes in the network.

#### Functions

##### `registerNode(string nodeId, string endpoint)`
Register a new node in the registry.

**Parameters:**
- `nodeId` (string): Unique identifier for the node
- `endpoint` (string): Network endpoint URL

**Events:**
- `NodeRegistered(string indexed nodeId, address indexed owner, string endpoint)`

**Example:**
```solidity
pulseRegistry.registerNode("executor-1", "http://node.example.com:3000");
```

##### `updateNode(string nodeId, string newEndpoint)`
Update the endpoint of a registered node (owner only).

**Parameters:**
- `nodeId` (string): Node identifier
- `newEndpoint` (string): New endpoint URL

##### `deactivateNode(string nodeId)`
Deactivate a node (owner only).

**Parameters:**
- `nodeId` (string): Node identifier

##### `activateNode(string nodeId)`
Activate a previously deactivated node (owner only).

**Parameters:**
- `nodeId` (string): Node identifier

##### `getNode(string nodeId)` (view)
Get information about a node.

**Parameters:**
- `nodeId` (string): Node identifier

**Returns:**
- `owner` (address): Node owner address
- `endpoint` (string): Node endpoint
- `registeredAt` (uint256): Registration timestamp
- `active` (bool): Active status

##### `isNodeActive(string nodeId)` (view)
Check if a node is active.

**Parameters:**
- `nodeId` (string): Node identifier

**Returns:**
- `bool`: True if node is active

---

### ZcashBridge

Bridge contract for cross-chain interoperability with Zcash.

#### Functions

##### `initiateBridge(string zcashAddress)` (payable)
Initiate a bridge transaction to Zcash.

**Parameters:**
- `zcashAddress` (string): Destination Zcash address

**Payable:** Send the amount to bridge as msg.value

**Events:**
- `BridgeInitiated(bytes32 indexed txId, address indexed sender, string zcashAddress, uint256 amount)`

**Example:**
```solidity
zcashBridge.initiateBridge{value: 1 ether}("z1abc123...");
```

##### `completeBridge(bytes32 txId)`
Mark a bridge transaction as completed (operators only).

**Parameters:**
- `txId` (bytes32): Transaction identifier

##### `failBridge(bytes32 txId, string reason)`
Mark a bridge transaction as failed and refund sender (operators only).

**Parameters:**
- `txId` (bytes32): Transaction identifier
- `reason` (string): Failure reason

##### `cancelBridge(bytes32 txId)`
Cancel a pending bridge transaction (sender only).

**Parameters:**
- `txId` (bytes32): Transaction identifier

##### `getTransaction(bytes32 txId)` (view)
Get bridge transaction details.

**Parameters:**
- `txId` (bytes32): Transaction identifier

**Returns:**
- `sender` (address): Transaction sender
- `zcashAddress` (string): Destination Zcash address
- `amount` (uint256): Bridge amount
- `timestamp` (uint256): Transaction timestamp
- `status` (BridgeStatus): Transaction status

##### `addOperator(address operator)`
Add a bridge operator (owner only).

**Parameters:**
- `operator` (address): Address to add as operator

##### `removeOperator(address operator)`
Remove a bridge operator (owner only).

**Parameters:**
- `operator` (address): Address to remove as operator

##### `updateBridgeFee(uint256 newFee)`
Update bridge fee in basis points (owner only).

**Parameters:**
- `newFee` (uint256): New fee (100 = 1%, max 1000 = 10%)

---

### AutoPostExecutor

Automated task scheduler and executor.

#### Enums

##### `TaskStatus`
- `Pending` (0): Task waiting to be executed
- `Executed` (1): Task successfully executed
- `Failed` (2): Task execution failed
- `Cancelled` (3): Task cancelled by creator

#### Functions

##### `createTask(address targetContract, bytes callData, uint256 executionTime, uint256 gasLimit, string description)`
Create a new automated task.

**Parameters:**
- `targetContract` (address): Contract to call when executing
- `callData` (bytes): Encoded function call data
- `executionTime` (uint256): Unix timestamp when task should execute
- `gasLimit` (uint256): Gas limit for execution
- `description` (string): Human-readable description

**Returns:**
- `taskId` (bytes32): Unique task identifier

**Events:**
- `TaskCreated(bytes32 indexed taskId, address indexed creator, address targetContract, uint256 executionTime)`

**Example:**
```javascript
const iface = new ethers.Interface(['function setValue(uint256 value)']);
const callData = iface.encodeFunctionData('setValue', [42]);
const executionTime = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now

const tx = await autoPostExecutor.createTask(
    targetContractAddress,
    callData,
    executionTime,
    300000,
    "Set value to 42"
);
```

##### `executeTask(bytes32 taskId)`
Execute a pending task (executors only).

**Parameters:**
- `taskId` (bytes32): Task identifier

**Events:**
- `TaskExecuted(bytes32 indexed taskId, bool success, bytes returnData)`
- `TaskFailed(bytes32 indexed taskId, string reason)`

##### `executeBatch(bytes32[] taskIds)`
Execute multiple tasks in batch (executors only).

**Parameters:**
- `taskIds` (bytes32[]): Array of task identifiers

##### `cancelTask(bytes32 taskId)`
Cancel a pending task (creator only).

**Parameters:**
- `taskId` (bytes32): Task identifier

##### `getTask(bytes32 taskId)` (view)
Get task details.

**Parameters:**
- `taskId` (bytes32): Task identifier

**Returns:**
- `creator` (address): Task creator
- `targetContract` (address): Target contract
- `callData` (bytes): Call data
- `executionTime` (uint256): Scheduled execution time
- `gasLimit` (uint256): Gas limit
- `status` (TaskStatus): Task status
- `description` (string): Task description

##### `getPendingTasks()` (view)
Get all pending tasks ready for execution.

**Returns:**
- `bytes32[]`: Array of pending task IDs

##### `addExecutor(address executor)`
Add an authorized executor (owner only).

**Parameters:**
- `executor` (address): Address to authorize

##### `removeExecutor(address executor)`
Remove an authorized executor (owner only).

**Parameters:**
- `executor` (address): Address to deauthorize

##### `updateMinExecutionDelay(uint256 newDelay)`
Update minimum execution delay (owner only).

**Parameters:**
- `newDelay` (uint256): New delay in seconds

---

## Executor Node Service

### Configuration

The executor node is configured via environment variables (see `.env.example`).

### Lifecycle

1. **Initialization**: Connects to blockchain, loads contracts
2. **Registration**: Registers node in PulseRegistry (if configured)
3. **Main Loop**: 
   - Polls for pending tasks
   - Executes ready tasks
   - Processes bridge transactions
   - Sleeps for poll interval
4. **Shutdown**: Graceful shutdown on SIGINT/SIGTERM

### Event Handling

The executor node listens for and responds to:
- `TaskCreated` events from AutoPostExecutor
- `BridgeInitiated` events from ZcashBridge
- Block confirmations for transaction finality

### Error Handling

- Automatic retry on RPC failures
- Graceful degradation if contracts not configured
- Read-only mode if private key not provided

---

## Usage Examples

### JavaScript/TypeScript

```javascript
const { ethers } = require('ethers');

// Setup
const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

// Load ABIs (from config/deployments.json or contract source)
const autoPostExecutorABI = [...];
const pulseRegistryABI = [...];
const zcashBridgeABI = [...];

// Create contract instances
const autoPostExecutor = new ethers.Contract(
    AUTOPOST_EXECUTOR_ADDRESS,
    autoPostExecutorABI,
    wallet
);

// Create a task
const iface = new ethers.Interface(['function transfer(address to, uint256 amount)']);
const callData = iface.encodeFunctionData('transfer', [recipientAddress, amount]);

const tx = await autoPostExecutor.createTask(
    tokenAddress,
    callData,
    Math.floor(Date.now() / 1000) + 86400, // Execute in 24 hours
    200000,
    "Transfer tokens to recipient"
);

const receipt = await tx.wait();
console.log('Task created:', receipt.hash);

// Query pending tasks
const pendingTasks = await autoPostExecutor.getPendingTasks();
console.log(`${pendingTasks.length} tasks pending`);
```

### Solidity

```solidity
pragma solidity ^0.8.21;

import "./AutoPostExecutor.sol";

contract MyContract {
    AutoPostExecutor public executor;
    
    constructor(address _executor) {
        executor = AutoPostExecutor(_executor);
    }
    
    function scheduleMyFunction(uint256 value) public {
        bytes memory callData = abi.encodeWithSignature(
            "myFunction(uint256)",
            value
        );
        
        executor.createTask(
            address(this),
            callData,
            block.timestamp + 1 hours,
            300000,
            "Call myFunction"
        );
    }
    
    function myFunction(uint256 value) public {
        // This will be called by the executor
        // ... your logic here
    }
}
```

---

## Rate Limits & Best Practices

### Gas Optimization
- Use batch execution when possible
- Set appropriate gas limits for tasks
- Monitor gas prices and adjust accordingly

### Security
- Validate all input parameters
- Use events for off-chain monitoring
- Implement access controls
- Test thoroughly before mainnet deployment

### Monitoring
- Monitor executor node health
- Track task execution success rates
- Set up alerts for failed transactions
- Log all important events

---

## Error Codes

### Common Errors

- `"Only owner can call this function"`: Caller is not the contract owner
- `"Only executors can call this function"`: Caller is not an authorized executor
- `"Task does not exist"`: Invalid task ID
- `"Task is not pending"`: Task already executed/failed/cancelled
- `"Execution time not reached"`: Task scheduled for future execution
- `"Node already registered"`: Node ID already in use
- `"Insufficient funds"`: Wallet balance too low for transaction

---

## Versioning

Current Version: 1.0.0

Contract upgrades will be announced in advance and may require migration scripts.
