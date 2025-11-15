// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title PulseRegistry
 * @dev Main registry contract for Super Reality Studios blockchain ecosystem
 * @notice Manages registration and tracking of nodes and entities in the network
 */
contract PulseRegistry {
    // Registry entry structure
    struct RegistryEntry {
        address owner;
        string nodeId;
        string endpoint;
        uint256 registeredAt;
        bool active;
    }

    // Mapping from node ID to registry entry
    mapping(string => RegistryEntry) public registry;
    
    // Array of all registered node IDs
    string[] public registeredNodes;
    
    // Owner of the contract
    address public owner;
    
    // Events
    event NodeRegistered(string indexed nodeId, address indexed owner, string endpoint);
    event NodeDeactivated(string indexed nodeId);
    event NodeActivated(string indexed nodeId);
    event NodeUpdated(string indexed nodeId, string newEndpoint);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyNodeOwner(string memory nodeId) {
        require(registry[nodeId].owner == msg.sender, "Only node owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Register a new node in the registry
     * @param nodeId Unique identifier for the node
     * @param endpoint Network endpoint for the node
     */
    function registerNode(string memory nodeId, string memory endpoint) public {
        require(bytes(registry[nodeId].nodeId).length == 0, "Node already registered");
        require(bytes(nodeId).length > 0, "Node ID cannot be empty");
        require(bytes(endpoint).length > 0, "Endpoint cannot be empty");
        
        registry[nodeId] = RegistryEntry({
            owner: msg.sender,
            nodeId: nodeId,
            endpoint: endpoint,
            registeredAt: block.timestamp,
            active: true
        });
        
        registeredNodes.push(nodeId);
        
        emit NodeRegistered(nodeId, msg.sender, endpoint);
    }
    
    /**
     * @dev Update node endpoint
     * @param nodeId Node identifier
     * @param newEndpoint New network endpoint
     */
    function updateNode(string memory nodeId, string memory newEndpoint) public onlyNodeOwner(nodeId) {
        require(registry[nodeId].active, "Node is not active");
        require(bytes(newEndpoint).length > 0, "Endpoint cannot be empty");
        
        registry[nodeId].endpoint = newEndpoint;
        
        emit NodeUpdated(nodeId, newEndpoint);
    }
    
    /**
     * @dev Deactivate a node
     * @param nodeId Node identifier
     */
    function deactivateNode(string memory nodeId) public onlyNodeOwner(nodeId) {
        require(registry[nodeId].active, "Node is already inactive");
        
        registry[nodeId].active = false;
        
        emit NodeDeactivated(nodeId);
    }
    
    /**
     * @dev Activate a node
     * @param nodeId Node identifier
     */
    function activateNode(string memory nodeId) public onlyNodeOwner(nodeId) {
        require(!registry[nodeId].active, "Node is already active");
        
        registry[nodeId].active = true;
        
        emit NodeActivated(nodeId);
    }
    
    /**
     * @dev Get node information
     * @param nodeId Node identifier
     * @return owner Node owner address
     * @return endpoint Node endpoint
     * @return registeredAt Registration timestamp
     * @return active Node active status
     */
    function getNode(string memory nodeId) public view returns (
        address,
        string memory,
        uint256,
        bool
    ) {
        RegistryEntry memory entry = registry[nodeId];
        return (entry.owner, entry.endpoint, entry.registeredAt, entry.active);
    }
    
    /**
     * @dev Get total number of registered nodes
     * @return Number of registered nodes
     */
    function getNodeCount() public view returns (uint256) {
        return registeredNodes.length;
    }
    
    /**
     * @dev Check if a node is registered and active
     * @param nodeId Node identifier
     * @return True if node is active
     */
    function isNodeActive(string memory nodeId) public view returns (bool) {
        return registry[nodeId].active;
    }
}
