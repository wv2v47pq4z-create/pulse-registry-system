// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title IResonanceRegistry
 * @notice Interface for the ResonanceRegistry contract
 * @dev Provides read-only access to resonance data and threshold checks
 */
interface IResonanceRegistry {
    /**
     * @notice Get the resonance score for an address
     * @param entity The address to query
     * @return The resonance score (0-1000 scale)
     */
    function getResonance(address entity) external view returns (uint32);

    /**
     * @notice Check if an entity meets a specific resonance floor
     * @param entity The address to check
     * @param floor The minimum resonance score required
     * @return True if the entity's resonance meets or exceeds the floor
     */
    function meetsResonanceFloor(address entity, uint32 floor) external view returns (bool);

    /**
     * @notice Check if an entity meets the global integrity floor
     * @param entity The address to check
     * @return True if the entity's resonance meets or exceeds the integrity floor
     */
    function meetsIntegrityFloor(address entity) external view returns (bool);

    /**
     * @notice Get the global integrity floor threshold
     * @return The integrity floor value
     */
    function integrityFloor() external view returns (uint32);

    /**
     * @notice Get the contract owner address
     * @return The owner address
     */
    function owner() external view returns (address);

    /**
     * @notice Check if an address is authorized as an oracle
     * @param oracle The address to check
     * @return True if the address is an authorized oracle
     */
    function oracles(address oracle) external view returns (bool);
}
