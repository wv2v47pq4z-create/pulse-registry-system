// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PulseRegistry.sol";

/**
 * @title ZcashBridge
 * @dev Bridge contract for interoperability with Zcash network
 * Auto-registration layer for Super Reality Studios blockchain ecosystem
 */
contract ZcashBridge {
    
    // Reference to PulseRegistry
    PulseRegistry public pulseRegistry;
    
    // Struct for bridge transaction
    struct BridgeTransaction {
        bytes32 zcashTxHash;
        address ethereumAddress;
        uint256 amount;
        uint256 timestamp;
        bool processed;
        uint256 pulseId;
    }
    
    // State variables
    mapping(bytes32 => BridgeTransaction) public bridgeTransactions;
    mapping(address => bytes32[]) public addressTransactions;
    uint256 public transactionCount;
    
    // Events
    event BridgeInitiated(
        bytes32 indexed zcashTxHash,
        address indexed ethereumAddress,
        uint256 amount,
        uint256 timestamp
    );
    
    event BridgeCompleted(
        bytes32 indexed zcashTxHash,
        uint256 pulseId
    );
    
    /**
     * @dev Constructor
     * @param _pulseRegistryAddress Address of the PulseRegistry contract
     */
    constructor(address _pulseRegistryAddress) {
        pulseRegistry = PulseRegistry(_pulseRegistryAddress);
    }
    
    /**
     * @dev Initiate a bridge transaction from Zcash to Ethereum
     * @param _zcashTxHash Transaction hash from Zcash network
     * @param _ethereumAddress Destination Ethereum address
     * @param _amount Amount to bridge
     */
    function initiateBridge(
        bytes32 _zcashTxHash,
        address _ethereumAddress,
        uint256 _amount
    ) public returns (bool) {
        require(_ethereumAddress != address(0), "Invalid Ethereum address");
        require(_amount > 0, "Amount must be greater than 0");
        require(!bridgeTransactions[_zcashTxHash].processed, "Transaction already processed");
        
        BridgeTransaction storage txn = bridgeTransactions[_zcashTxHash];
        txn.zcashTxHash = _zcashTxHash;
        txn.ethereumAddress = _ethereumAddress;
        txn.amount = _amount;
        txn.timestamp = block.timestamp;
        txn.processed = false;
        txn.pulseId = 0;
        
        addressTransactions[_ethereumAddress].push(_zcashTxHash);
        transactionCount++;
        
        emit BridgeInitiated(_zcashTxHash, _ethereumAddress, _amount, block.timestamp);
        
        return true;
    }
    
    /**
     * @dev Complete bridge transaction and register pulse
     * @param _zcashTxHash Transaction hash from Zcash network
     */
    function completeBridge(bytes32 _zcashTxHash) public returns (uint256) {
        BridgeTransaction storage txn = bridgeTransactions[_zcashTxHash];
        require(txn.timestamp > 0, "Transaction does not exist");
        require(!txn.processed, "Transaction already processed");
        
        // Register pulse for this bridge transaction
        string memory systemId = string(abi.encodePacked("ZcashBridge-", toHexString(_zcashTxHash)));
        uint256 pulseId = pulseRegistry.registerPulse(
            PulseRegistry.PulseType.RealityCheck,
            systemId,
            PulseRegistry.PulseStatus.APPROVED,
            0, // Zero latency
            10000, // 100% success rate
            "Zcash bridge transaction completed successfully"
        );
        
        txn.processed = true;
        txn.pulseId = pulseId;
        
        emit BridgeCompleted(_zcashTxHash, pulseId);
        
        return pulseId;
    }
    
    /**
     * @dev Get bridge transaction details
     * @param _zcashTxHash Transaction hash from Zcash network
     */
    function getBridgeTransaction(bytes32 _zcashTxHash) public view returns (
        address ethereumAddress,
        uint256 amount,
        uint256 timestamp,
        bool processed,
        uint256 pulseId
    ) {
        BridgeTransaction storage txn = bridgeTransactions[_zcashTxHash];
        return (
            txn.ethereumAddress,
            txn.amount,
            txn.timestamp,
            txn.processed,
            txn.pulseId
        );
    }
    
    /**
     * @dev Get all bridge transactions for an address
     * @param _address Ethereum address
     */
    function getAddressTransactions(address _address) public view returns (bytes32[] memory) {
        return addressTransactions[_address];
    }
    
    /**
     * @dev Convert bytes32 to hex string (helper function)
     */
    function toHexString(bytes32 _data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i*2] = alphabet[uint8(_data[i] >> 4)];
            str[1+i*2] = alphabet[uint8(_data[i] & 0x0f)];
        }
        return string(str);
    }
}
