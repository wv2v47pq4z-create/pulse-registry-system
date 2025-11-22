// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ResonanceTypes.sol";

/**
 * @title ResonanceRegistry
 * @notice A registry for tracking resonance scores of entities with oracle-based updates
 * @dev Implements a 0-1000 scale resonance scoring system (representing 0.000-1.000)
 *      with owner/oracle access control and a global integrity floor threshold
 */
contract ResonanceRegistry {
    /// @notice The contract owner who can manage oracles and update the integrity floor
    address public owner;

    /// @notice Global integrity floor threshold (0-1000 scale)
    /// @dev Entities must meet or exceed this threshold to pass integrity checks
    uint32 public integrityFloor;

    /// @notice Maximum allowed resonance score (1000 = 1.000 in decimal form)
    uint32 public constant MAX_RESONANCE = 1000;

    /// @notice Mapping of authorized oracle addresses
    mapping(address => bool) public oracles;

    /// @notice Mapping of entity addresses to their resonance data
    mapping(address => Resonance) private resonances;

    /// @notice Emitted when a new oracle is authorized
    /// @param oracle The address of the newly authorized oracle
    event OracleSet(address indexed oracle);

    /// @notice Emitted when an oracle is removed
    /// @param oracle The address of the removed oracle
    event OracleRemoved(address indexed oracle);

    /// @notice Emitted when the integrity floor is updated
    /// @param newFloor The new integrity floor value
    event IntegrityFloorUpdated(uint32 newFloor);

    /// @notice Emitted when a resonance score is set or updated
    /// @param entity The address whose resonance was updated
    /// @param score The new resonance score
    /// @param oracle The oracle that performed the update
    event ResonanceSet(address indexed entity, uint32 score, address indexed oracle);

    /// @notice Emitted when ownership is transferred
    /// @param previousOwner The address of the previous owner
    /// @param newOwner The address of the new owner
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev Restricts function access to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "ResonanceRegistry: caller is not the owner");
        _;
    }

    /// @dev Restricts function access to authorized oracles
    modifier onlyOracle() {
        require(oracles[msg.sender], "ResonanceRegistry: caller is not an oracle");
        _;
    }

    /**
     * @notice Initializes the registry with an integrity floor
     * @param _integrityFloor The initial global integrity floor (0-1000 scale)
     */
    constructor(uint32 _integrityFloor) {
        require(_integrityFloor <= MAX_RESONANCE, "ResonanceRegistry: floor exceeds maximum");
        owner = msg.sender;
        integrityFloor = _integrityFloor;
        emit OwnershipTransferred(address(0), msg.sender);
        emit IntegrityFloorUpdated(_integrityFloor);
    }

    /**
     * @notice Transfers ownership of the contract
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ResonanceRegistry: new owner is zero address");
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /**
     * @notice Authorizes a new oracle
     * @param oracle The address to authorize as an oracle
     */
    function setOracle(address oracle) external onlyOwner {
        require(oracle != address(0), "ResonanceRegistry: oracle is zero address");
        require(!oracles[oracle], "ResonanceRegistry: oracle already set");
        oracles[oracle] = true;
        emit OracleSet(oracle);
    }

    /**
     * @notice Removes an oracle's authorization
     * @param oracle The address to remove from oracles
     */
    function removeOracle(address oracle) external onlyOwner {
        require(oracles[oracle], "ResonanceRegistry: oracle not found");
        oracles[oracle] = false;
        emit OracleRemoved(oracle);
    }

    /**
     * @notice Updates the global integrity floor
     * @param newFloor The new integrity floor value (0-1000 scale)
     */
    function setIntegrityFloor(uint32 newFloor) external onlyOwner {
        require(newFloor <= MAX_RESONANCE, "ResonanceRegistry: floor exceeds maximum");
        integrityFloor = newFloor;
        emit IntegrityFloorUpdated(newFloor);
    }

    /**
     * @notice Sets the resonance score for an entity
     * @dev Only callable by authorized oracles
     * @param entity The address to set resonance for
     * @param score The resonance score (0-1000 scale)
     */
    function setResonance(address entity, uint32 score) external onlyOracle {
        require(entity != address(0), "ResonanceRegistry: entity is zero address");
        require(score <= MAX_RESONANCE, "ResonanceRegistry: score exceeds maximum");
        
        resonances[entity] = Resonance({
            score: score,
            lastUpdated: uint64(block.timestamp)
        });
        
        emit ResonanceSet(entity, score, msg.sender);
    }

    /**
     * @notice Gets the resonance score for an entity
     * @param entity The address to query
     * @return The resonance score (0-1000 scale)
     */
    function getResonance(address entity) external view returns (uint32) {
        return resonances[entity].score;
    }

    /**
     * @notice Gets the full resonance data for an entity
     * @param entity The address to query
     * @return score The resonance score
     * @return lastUpdated The timestamp of the last update
     */
    function getResonanceData(address entity) external view returns (uint32 score, uint64 lastUpdated) {
        Resonance memory res = resonances[entity];
        return (res.score, res.lastUpdated);
    }

    /**
     * @notice Checks if an entity meets a specific resonance floor
     * @param entity The address to check
     * @param floor The minimum resonance score required
     * @return True if the entity's resonance meets or exceeds the floor
     */
    function meetsResonanceFloor(address entity, uint32 floor) external view returns (bool) {
        return resonances[entity].score >= floor;
    }

    /**
     * @notice Checks if an entity meets the global integrity floor
     * @param entity The address to check
     * @return True if the entity's resonance meets or exceeds the integrity floor
     */
    function meetsIntegrityFloor(address entity) external view returns (bool) {
        return resonances[entity].score >= integrityFloor;
    }
}

/*
═══════════════════════════════════════════════════════════════════════════════
MANUAL TEST CHECKLIST FOR REMIX IDE
═══════════════════════════════════════════════════════════════════════════════

This checklist helps you manually verify the ResonanceRegistry contract in Remix.

STEP 1: DEPLOY THE CONTRACT
────────────────────────────
1. Open Remix IDE (remix.ethereum.org)
2. Create new files and paste all contract code:
   - ResonanceTypes.sol
   - IResonanceRegistry.sol
   - ResonanceRegistry.sol
   - ResonanceDeployer.sol (optional, or deploy directly)
   - ResonanceGateExample.sol
3. Compile ResonanceRegistry.sol (Solidity ^0.8.21)
4. In Deploy & Run tab:
   - Select "Injected Provider" or "Remix VM" environment
   - Deploy ResonanceRegistry with constructor parameter:
     * integrityFloor: 500 (represents 0.500 threshold)
5. Note the deployed contract address

STEP 2: SET UP AN ORACLE
─────────────────────────
1. From the owner account (deployer), call:
   - setOracle(address oracle)
   - Use a different test address as the oracle
2. Verify oracle was set:
   - Call oracles(address) with the oracle address
   - Should return: true

STEP 3: SET RESONANCE SCORES
─────────────────────────────
1. Switch to the oracle account in Remix
2. Call setResonance(address entity, uint32 score):
   - entity: address of any test account
   - score: 750 (represents 0.750 resonance)
3. Verify the transaction succeeds
4. Try calling setResonance from a non-oracle account:
   - Should revert with "caller is not an oracle"

STEP 4: READ RESONANCE DATA
────────────────────────────
1. Call getResonance(address entity):
   - entity: the address you set in Step 3
   - Should return: 750
2. Call getResonanceData(address entity):
   - Should return: (750, timestamp)

STEP 5: VERIFY THRESHOLD CHECKS
────────────────────────────────
1. Call meetsResonanceFloor(address entity, uint32 floor):
   - entity: test address with score 750
   - floor: 500
   - Should return: true
   - floor: 800
   - Should return: false

2. Call meetsIntegrityFloor(address entity):
   - entity: test address with score 750
   - integrityFloor is 500 (from deployment)
   - Should return: true

3. Set a low score for another address:
   - setResonance(anotherAddress, 300)
   - Call meetsIntegrityFloor(anotherAddress)
   - Should return: false

STEP 6: TEST WITH RESONANCE GATE EXAMPLE
─────────────────────────────────────────
1. Deploy ResonanceGateExample:
   - Constructor parameter: address of deployed ResonanceRegistry
2. From an account with resonance >= 500:
   - Call joinIfResonant(500)
   - Should succeed
3. Call hasJoined(msg.sender):
   - Should return: true
4. From an account with no resonance or low resonance:
   - Call joinIfResonant(500)
   - Should revert with "Resonance too low"

STEP 7: VERIFY ACCESS CONTROL
──────────────────────────────
1. From a non-owner account, try:
   - setOracle(address) → should revert
   - setIntegrityFloor(uint32) → should revert
   - removeOracle(address) → should revert
2. From owner account:
   - setIntegrityFloor(700) → should succeed
   - Verify: integrityFloor() returns 700

STEP 8: TEST EDGE CASES
────────────────────────
1. Try setResonance with score > 1000:
   - Should revert with "score exceeds maximum"
2. Try setOracle with zero address:
   - Should revert with "oracle is zero address"
3. Try setResonance for zero address:
   - Should revert with "entity is zero address"

═══════════════════════════════════════════════════════════════════════════════
END OF MANUAL TEST CHECKLIST
═══════════════════════════════════════════════════════════════════════════════
*/
