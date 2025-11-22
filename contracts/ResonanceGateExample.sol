// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IResonanceRegistry.sol";

/**
 * @title ResonanceGateExample
 * @notice Example consumer contract demonstrating resonance-gated functionality
 * @dev Uses IResonanceRegistry to verify caller resonance before allowing access
 */
contract ResonanceGateExample {
    /// @notice The resonance registry used for verification
    IResonanceRegistry public immutable registry;

    /// @notice Mapping of addresses that have successfully joined
    mapping(address => bool) private joined;

    /// @notice Emitted when a user successfully joins
    /// @param user The address that joined
    /// @param resonance The user's resonance score at time of joining
    event UserJoined(address indexed user, uint32 resonance);

    /**
     * @notice Initializes the gate with a registry address
     * @param _registry The address of the ResonanceRegistry contract
     */
    constructor(address _registry) {
        require(_registry != address(0), "ResonanceGateExample: registry is zero address");
        registry = IResonanceRegistry(_registry);
    }

    /**
     * @notice Allows a user to join if they meet the minimum resonance requirement
     * @param minScore The minimum resonance score required to join
     * @dev Reverts if the caller's resonance is below the threshold
     */
    function joinIfResonant(uint32 minScore) external {
        require(
            registry.meetsResonanceFloor(msg.sender, minScore),
            "ResonanceGateExample: Resonance too low"
        );
        
        require(!joined[msg.sender], "ResonanceGateExample: Already joined");
        
        joined[msg.sender] = true;
        
        uint32 userResonance = registry.getResonance(msg.sender);
        emit UserJoined(msg.sender, userResonance);
    }

    /**
     * @notice Checks if a user has joined
     * @param user The address to check
     * @return True if the user has joined
     */
    function hasJoined(address user) external view returns (bool) {
        return joined[user];
    }

    /**
     * @notice Gets the registry address
     * @return The address of the resonance registry
     */
    function getRegistry() external view returns (address) {
        return address(registry);
    }

    /**
     * @notice Checks if a user can join with a given minimum score
     * @param user The address to check
     * @param minScore The minimum score threshold
     * @return True if the user meets the requirement and hasn't joined yet
     */
    function canJoin(address user, uint32 minScore) external view returns (bool) {
        return !joined[user] && registry.meetsResonanceFloor(user, minScore);
    }
}
