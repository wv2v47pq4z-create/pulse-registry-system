// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ResonanceRegistry.sol";

/**
 * @title ResonanceDeployer
 * @notice Helper contract for deploying ResonanceRegistry instances
 * @dev Provides a simple factory pattern for creating new registries
 */
contract ResonanceDeployer {
    /// @notice Emitted when a new ResonanceRegistry is deployed
    /// @param registry The address of the newly deployed registry
    /// @param owner The owner of the new registry
    /// @param integrityFloor The integrity floor set for the new registry
    event RegistryDeployed(address indexed registry, address indexed owner, uint32 integrityFloor);

    /**
     * @notice Deploys a new ResonanceRegistry contract
     * @param integrityFloor The initial global integrity floor (0-1000 scale)
     * @return The address of the newly deployed ResonanceRegistry
     */
    function deployResonanceRegistry(uint32 integrityFloor) external returns (address) {
        ResonanceRegistry registry = new ResonanceRegistry(integrityFloor);
        
        // Transfer ownership to the caller
        registry.transferOwnership(msg.sender);
        
        emit RegistryDeployed(address(registry), msg.sender, integrityFloor);
        
        return address(registry);
    }
}
