// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title ZcashBridge
 * @dev Bridge contract for Zcash interoperability
 * @notice Facilitates cross-chain communication between Pulse network and Zcash
 */
contract ZcashBridge {
    // Bridge transaction structure
    struct BridgeTransaction {
        bytes32 txId;
        address sender;
        string zcashAddress;
        uint256 amount;
        uint256 timestamp;
        BridgeStatus status;
    }
    
    // Bridge status enumeration
    enum BridgeStatus {
        Pending,
        Completed,
        Failed,
        Cancelled
    }
    
    // Mapping from transaction ID to bridge transaction
    mapping(bytes32 => BridgeTransaction) public transactions;
    
    // Array of all transaction IDs
    bytes32[] public transactionIds;
    
    // Owner of the contract
    address public owner;
    
    // Authorized bridge operators
    mapping(address => bool) public operators;
    
    // Bridge fee (in basis points, 100 = 1%)
    uint256 public bridgeFee = 100; // 1%
    
    // Events
    event BridgeInitiated(bytes32 indexed txId, address indexed sender, string zcashAddress, uint256 amount);
    event BridgeCompleted(bytes32 indexed txId);
    event BridgeFailed(bytes32 indexed txId, string reason);
    event BridgeCancelled(bytes32 indexed txId);
    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);
    event BridgeFeeUpdated(uint256 newFee);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyOperator() {
        require(operators[msg.sender], "Only operators can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        operators[msg.sender] = true;
    }
    
    /**
     * @dev Initiate a bridge transaction to Zcash
     * @param zcashAddress Destination Zcash address
     */
    function initiateBridge(string memory zcashAddress) public payable {
        require(msg.value > 0, "Amount must be greater than 0");
        require(bytes(zcashAddress).length > 0, "Zcash address cannot be empty");
        
        bytes32 txId = keccak256(abi.encodePacked(msg.sender, zcashAddress, msg.value, block.timestamp));
        
        require(transactions[txId].timestamp == 0, "Transaction already exists");
        
        transactions[txId] = BridgeTransaction({
            txId: txId,
            sender: msg.sender,
            zcashAddress: zcashAddress,
            amount: msg.value,
            timestamp: block.timestamp,
            status: BridgeStatus.Pending
        });
        
        transactionIds.push(txId);
        
        emit BridgeInitiated(txId, msg.sender, zcashAddress, msg.value);
    }
    
    /**
     * @dev Complete a bridge transaction
     * @param txId Transaction ID
     */
    function completeBridge(bytes32 txId) public onlyOperator {
        require(transactions[txId].timestamp > 0, "Transaction does not exist");
        require(transactions[txId].status == BridgeStatus.Pending, "Transaction is not pending");
        
        transactions[txId].status = BridgeStatus.Completed;
        
        emit BridgeCompleted(txId);
    }
    
    /**
     * @dev Mark a bridge transaction as failed
     * @param txId Transaction ID
     * @param reason Failure reason
     */
    function failBridge(bytes32 txId, string memory reason) public onlyOperator {
        require(transactions[txId].timestamp > 0, "Transaction does not exist");
        require(transactions[txId].status == BridgeStatus.Pending, "Transaction is not pending");
        
        transactions[txId].status = BridgeStatus.Failed;
        
        // Refund the sender
        payable(transactions[txId].sender).transfer(transactions[txId].amount);
        
        emit BridgeFailed(txId, reason);
    }
    
    /**
     * @dev Cancel a bridge transaction (sender only)
     * @param txId Transaction ID
     */
    function cancelBridge(bytes32 txId) public {
        require(transactions[txId].timestamp > 0, "Transaction does not exist");
        require(transactions[txId].sender == msg.sender, "Only sender can cancel");
        require(transactions[txId].status == BridgeStatus.Pending, "Transaction is not pending");
        
        transactions[txId].status = BridgeStatus.Cancelled;
        
        // Refund the sender (minus bridge fee)
        uint256 fee = (transactions[txId].amount * bridgeFee) / 10000;
        uint256 refundAmount = transactions[txId].amount - fee;
        payable(msg.sender).transfer(refundAmount);
        
        emit BridgeCancelled(txId);
    }
    
    /**
     * @dev Add a bridge operator
     * @param operator Address to add as operator
     */
    function addOperator(address operator) public onlyOwner {
        require(!operators[operator], "Address is already an operator");
        operators[operator] = true;
        emit OperatorAdded(operator);
    }
    
    /**
     * @dev Remove a bridge operator
     * @param operator Address to remove as operator
     */
    function removeOperator(address operator) public onlyOwner {
        require(operators[operator], "Address is not an operator");
        require(operator != owner, "Cannot remove owner as operator");
        operators[operator] = false;
        emit OperatorRemoved(operator);
    }
    
    /**
     * @dev Update bridge fee
     * @param newFee New fee in basis points
     */
    function updateBridgeFee(uint256 newFee) public onlyOwner {
        require(newFee <= 1000, "Fee cannot exceed 10%");
        bridgeFee = newFee;
        emit BridgeFeeUpdated(newFee);
    }
    
    /**
     * @dev Get transaction details
     * @param txId Transaction ID
     */
    function getTransaction(bytes32 txId) public view returns (
        address sender,
        string memory zcashAddress,
        uint256 amount,
        uint256 timestamp,
        BridgeStatus status
    ) {
        BridgeTransaction memory tx = transactions[txId];
        return (tx.sender, tx.zcashAddress, tx.amount, tx.timestamp, tx.status);
    }
    
    /**
     * @dev Get total number of transactions
     */
    function getTransactionCount() public view returns (uint256) {
        return transactionIds.length;
    }
    
    /**
     * @dev Withdraw accumulated fees (owner only)
     */
    function withdrawFees() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
