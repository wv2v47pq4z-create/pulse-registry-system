// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title AutoPostExecutor
 * @dev Automatic posting and execution logic for SR-OS Remote Executor Node
 * @notice Manages automated task execution and transaction posting
 */
contract AutoPostExecutor {
    // Task structure
    struct Task {
        bytes32 taskId;
        address creator;
        address targetContract;
        bytes callData;
        uint256 executionTime;
        uint256 gasLimit;
        TaskStatus status;
        string description;
    }
    
    // Task status enumeration
    enum TaskStatus {
        Pending,
        Executed,
        Failed,
        Cancelled
    }
    
    // Mapping from task ID to task
    mapping(bytes32 => Task) public tasks;
    
    // Array of all task IDs
    bytes32[] public taskIds;
    
    // Owner of the contract
    address public owner;
    
    // Authorized executors
    mapping(address => bool) public executors;
    
    // Minimum execution delay (seconds)
    uint256 public minExecutionDelay = 60;
    
    // Events
    event TaskCreated(bytes32 indexed taskId, address indexed creator, address targetContract, uint256 executionTime);
    event TaskExecuted(bytes32 indexed taskId, bool success, bytes returnData);
    event TaskFailed(bytes32 indexed taskId, string reason);
    event TaskCancelled(bytes32 indexed taskId);
    event ExecutorAdded(address indexed executor);
    event ExecutorRemoved(address indexed executor);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyExecutor() {
        require(executors[msg.sender], "Only executors can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        executors[msg.sender] = true;
    }
    
    /**
     * @dev Create a new automated task
     * @param targetContract Contract to call
     * @param callData Call data for the contract
     * @param executionTime Timestamp when task should be executed
     * @param gasLimit Gas limit for execution
     * @param description Task description
     */
    function createTask(
        address targetContract,
        bytes memory callData,
        uint256 executionTime,
        uint256 gasLimit,
        string memory description
    ) public returns (bytes32) {
        require(targetContract != address(0), "Invalid target contract");
        require(executionTime >= block.timestamp + minExecutionDelay, "Execution time too soon");
        require(gasLimit > 0 && gasLimit <= block.gaslimit, "Invalid gas limit");
        
        bytes32 taskId = keccak256(abi.encodePacked(
            msg.sender,
            targetContract,
            callData,
            executionTime,
            block.timestamp
        ));
        
        require(tasks[taskId].creator == address(0), "Task already exists");
        
        tasks[taskId] = Task({
            taskId: taskId,
            creator: msg.sender,
            targetContract: targetContract,
            callData: callData,
            executionTime: executionTime,
            gasLimit: gasLimit,
            status: TaskStatus.Pending,
            description: description
        });
        
        taskIds.push(taskId);
        
        emit TaskCreated(taskId, msg.sender, targetContract, executionTime);
        
        return taskId;
    }
    
    /**
     * @dev Execute a pending task
     * @param taskId Task ID to execute
     */
    function executeTask(bytes32 taskId) public onlyExecutor {
        Task storage task = tasks[taskId];
        
        require(task.creator != address(0), "Task does not exist");
        require(task.status == TaskStatus.Pending, "Task is not pending");
        require(block.timestamp >= task.executionTime, "Execution time not reached");
        
        // Execute the task
        (bool success, bytes memory returnData) = task.targetContract.call{gas: task.gasLimit}(task.callData);
        
        if (success) {
            task.status = TaskStatus.Executed;
            emit TaskExecuted(taskId, success, returnData);
        } else {
            task.status = TaskStatus.Failed;
            emit TaskFailed(taskId, "Execution failed");
        }
    }
    
    /**
     * @dev Execute multiple tasks in batch
     * @param taskIdArray Array of task IDs to execute
     */
    function executeBatch(bytes32[] memory taskIdArray) public onlyExecutor {
        for (uint256 i = 0; i < taskIdArray.length; i++) {
            Task storage task = tasks[taskIdArray[i]];
            
            if (task.creator != address(0) && 
                task.status == TaskStatus.Pending && 
                block.timestamp >= task.executionTime) {
                
                (bool success, bytes memory returnData) = task.targetContract.call{gas: task.gasLimit}(task.callData);
                
                if (success) {
                    task.status = TaskStatus.Executed;
                    emit TaskExecuted(taskIdArray[i], success, returnData);
                } else {
                    task.status = TaskStatus.Failed;
                    emit TaskFailed(taskIdArray[i], "Execution failed");
                }
            }
        }
    }
    
    /**
     * @dev Cancel a pending task (creator only)
     * @param taskId Task ID to cancel
     */
    function cancelTask(bytes32 taskId) public {
        Task storage task = tasks[taskId];
        
        require(task.creator != address(0), "Task does not exist");
        require(task.creator == msg.sender, "Only creator can cancel task");
        require(task.status == TaskStatus.Pending, "Task is not pending");
        
        task.status = TaskStatus.Cancelled;
        
        emit TaskCancelled(taskId);
    }
    
    /**
     * @dev Add an executor
     * @param executor Address to add as executor
     */
    function addExecutor(address executor) public onlyOwner {
        require(!executors[executor], "Address is already an executor");
        executors[executor] = true;
        emit ExecutorAdded(executor);
    }
    
    /**
     * @dev Remove an executor
     * @param executor Address to remove as executor
     */
    function removeExecutor(address executor) public onlyOwner {
        require(executors[executor], "Address is not an executor");
        require(executor != owner, "Cannot remove owner as executor");
        executors[executor] = false;
        emit ExecutorRemoved(executor);
    }
    
    /**
     * @dev Update minimum execution delay
     * @param newDelay New delay in seconds
     */
    function updateMinExecutionDelay(uint256 newDelay) public onlyOwner {
        minExecutionDelay = newDelay;
    }
    
    /**
     * @dev Get task details
     * @param taskId Task ID
     */
    function getTask(bytes32 taskId) public view returns (
        address creator,
        address targetContract,
        bytes memory callData,
        uint256 executionTime,
        uint256 gasLimit,
        TaskStatus status,
        string memory description
    ) {
        Task memory task = tasks[taskId];
        return (
            task.creator,
            task.targetContract,
            task.callData,
            task.executionTime,
            task.gasLimit,
            task.status,
            task.description
        );
    }
    
    /**
     * @dev Get total number of tasks
     */
    function getTaskCount() public view returns (uint256) {
        return taskIds.length;
    }
    
    /**
     * @dev Get pending tasks ready for execution
     */
    function getPendingTasks() public view returns (bytes32[] memory) {
        uint256 count = 0;
        
        // Count pending tasks
        for (uint256 i = 0; i < taskIds.length; i++) {
            if (tasks[taskIds[i]].status == TaskStatus.Pending && 
                block.timestamp >= tasks[taskIds[i]].executionTime) {
                count++;
            }
        }
        
        // Create array of pending task IDs
        bytes32[] memory pendingTaskIds = new bytes32[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < taskIds.length; i++) {
            if (tasks[taskIds[i]].status == TaskStatus.Pending && 
                block.timestamp >= tasks[taskIds[i]].executionTime) {
                pendingTaskIds[index] = taskIds[i];
                index++;
            }
        }
        
        return pendingTaskIds;
    }
}
