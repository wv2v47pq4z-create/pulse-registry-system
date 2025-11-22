// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IPulseToken {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

/**
 * @title PulseEscrowPool
 * @notice Task-based escrow for Pulse Tokens.
 *
 * Core idea:
 * - Tokens must exist BEFORE use (no minting here).
 * - A "client" creates a task by depositing PULSE into escrow.
 * - A "worker" is assigned to that task.
 * - When work is done, the client (or an authorized resolver) releases tokens
 *   from the escrowed budget to the worker.
 *
 * This matches the closed-loop model:
 * - Tokens only move from pre-funded escrows to contributors.
 * - No new supply is created inside this contract.
 *
 * @dev Token Compatibility Note:
 * This contract expects IPulseToken to be a standard ERC20 implementation
 * that returns boolean values from transfer and transferFrom operations.
 * For maximum compatibility with non-standard tokens, consider using
 * OpenZeppelin's SafeERC20 wrapper or verify token behavior before deployment.
 */
contract PulseEscrowPool {
    // ------------------------------------------------------------------------
    // Types
    // ------------------------------------------------------------------------

    struct Task {
        address client;          // who funded the task
        address worker;          // who should be paid
        uint256 budget;          // total tokens escrowed for this task
        uint256 paidOut;         // total paid out so far
        bool active;             // if false, escrow is closed
    }

    // ------------------------------------------------------------------------
    // Storage
    // ------------------------------------------------------------------------

    IPulseToken public immutable pulse;
    address public owner;
    mapping(uint256 => Task) public tasks;
    uint256 public nextTaskId;

    // Optional resolver: can help finalize disputes or auto-release funds.
    address public resolver;

    // ------------------------------------------------------------------------
    // Events
    // ------------------------------------------------------------------------

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ResolverUpdated(address indexed newResolver);

    event TaskCreated(
        uint256 indexed taskId,
        address indexed client,
        address indexed worker,
        uint256 budget
    );

    event TaskPaymentReleased(
        uint256 indexed taskId,
        address indexed to,
        uint256 amount,
        uint256 totalPaidOut
    );

    event TaskClosed(uint256 indexed taskId, uint256 remainingRefunded);

    // ------------------------------------------------------------------------
    // Modifiers
    // ------------------------------------------------------------------------

    modifier onlyOwner() {
        require(msg.sender == owner, "ESCROW: not owner");
        _;
    }

    modifier onlyClientOrResolver(uint256 taskId) {
        Task memory t = tasks[taskId];
        require(t.client != address(0), "ESCROW: task not found");
        require(
            msg.sender == t.client || (resolver != address(0) && msg.sender == resolver),
            "ESCROW: not client/resolver"
        );
        _;
    }

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------

    constructor(address pulseTokenAddress) {
        require(pulseTokenAddress != address(0), "ESCROW: pulse zero");
        pulse = IPulseToken(pulseTokenAddress);
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // ------------------------------------------------------------------------
    // Admin
    // ------------------------------------------------------------------------

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ESCROW: owner zero");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setResolver(address newResolver) external onlyOwner {
        resolver = newResolver;
        emit ResolverUpdated(newResolver);
    }

    // ------------------------------------------------------------------------
    // Core: Task lifecycle
    // ------------------------------------------------------------------------

    /**
     * @notice Create a new escrowed task.
     *
     * @param worker  Address that should receive payouts.
     * @param budget  Amount of PULSE to transfer into escrow for this task.
     *
     * Requirements:
     * - Caller must have approved this contract to spend `budget` PULSE.
     */
    function createTask(address worker, uint256 budget) external returns (uint256 taskId) {
        require(worker != address(0), "ESCROW: worker zero");
        require(budget > 0, "ESCROW: budget zero");

        taskId = nextTaskId++;
        tasks[taskId] = Task({
            client: msg.sender,
            worker: worker,
            budget: budget,
            paidOut: 0,
            active: true
        });

        // Pull tokens from client into escrow.
        bool ok = pulse.transferFrom(msg.sender, address(this), budget);
        require(ok, "ESCROW: transferFrom failed");

        emit TaskCreated(taskId, msg.sender, worker, budget);
    }

    /**
     * @notice Release payment from an active task to the worker.
     *
     * @param taskId  ID of the task.
     * @param amount  Amount of PULSE to release.
     *
     * Requirements:
     * - Caller is task client or global resolver.
     * - Task must be active.
     * - Amount must not exceed remaining budget.
     */
    function releasePayment(uint256 taskId, uint256 amount) external onlyClientOrResolver(taskId) {
        Task storage t = tasks[taskId];
        require(t.active, "ESCROW: inactive");
        require(amount > 0, "ESCROW: amount zero");

        uint256 remaining = t.budget - t.paidOut;
        require(amount <= remaining, "ESCROW: exceeds remaining");

        t.paidOut += amount;

        bool ok = pulse.transfer(t.worker, amount);
        require(ok, "ESCROW: transfer failed");

        emit TaskPaymentReleased(taskId, t.worker, amount, t.paidOut);
    }

    /**
     * @notice Close the task and refund any unused budget to the client.
     *
     * @param taskId ID of the task.
     *
     * Requirements:
     * - Caller is task client or resolver.
     * - Task must be active.
     */
    function closeTask(uint256 taskId) external onlyClientOrResolver(taskId) {
        Task storage t = tasks[taskId];
        require(t.active, "ESCROW: already closed");

        t.active = false;
        uint256 remaining = t.budget - t.paidOut;

        if (remaining > 0) {
            bool ok = pulse.transfer(t.client, remaining);
            require(ok, "ESCROW: refund failed");
        }

        emit TaskClosed(taskId, remaining);
    }

    // ------------------------------------------------------------------------
    // Views
    // ------------------------------------------------------------------------

    function remainingBudget(uint256 taskId) external view returns (uint256) {
        Task memory t = tasks[taskId];
        if (!t.active) return 0;
        return t.budget - t.paidOut;
    }
}
