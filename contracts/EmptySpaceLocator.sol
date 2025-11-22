// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title EmptySpaceLocator
 * @notice Contract used ONLY to locate "empty space" on-chain:
 *         addresses where there is no contract code and that are not
 *         tagged as part of the Pulse / Resonance / ZacEcho ecosystem.
 *
 * Concept:
 * - Owner tags known ecosystem contracts as "occupied".
 * - Anyone can call `probeSpace(target, contextTag)`.
 * - If `target`:
 *      * is zero address         → revert
 *      * is tagged as occupied   → ignored
 *      * has contract code       → ignored (not empty space)
 *      * has no contract code    → recorded as EMPTY SPACE
 *
 * This contract does NOT:
 * - Track resonance, frequencies, or pulses.
 * - Classify contracts by type (Pulse/Resonance/ZacEcho).
 * - Aggregate any global state other than "where is empty".
 */
contract EmptySpaceLocator {
    // ------------------------------------------------------------------------
    // Types
    // ------------------------------------------------------------------------

    enum OccupancyType {
        None,        // unknown / not tagged
        Occupied     // known ecosystem node (Pulse / Resonance / ZacEcho / other)
    }

    struct EmptySpaceRecord {
        bool exists;          // has this address ever been observed as empty
        bytes32 firstTag;     // first context tag under which it was observed
        bytes32 lastTag;      // most recent context tag
        uint64 firstSeen;     // timestamp when first observed
        uint64 lastSeen;      // timestamp when last observed
        uint256 observations; // number of times observed as empty
    }

    // ------------------------------------------------------------------------
    // Storage
    // ------------------------------------------------------------------------

    address public owner;

    // Ecosystem occupancy tags (anything set to Occupied is considered NON-empty)
    mapping(address => OccupancyType) public occupancyOf;

    // Empty space map
    mapping(address => EmptySpaceRecord) private _empties;
    address[] public emptyList;

    // ------------------------------------------------------------------------
    // Events
    // ------------------------------------------------------------------------

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice A contract/address was tagged as occupied ecosystem space.
    event OccupiedTagged(address indexed target);

    /// @notice An address was observed as empty space.
    event EmptySpaceObserved(
        address indexed observer,
        address indexed target,
        bytes32 indexed contextTag,
        uint64 timestamp,
        uint256 totalObservations
    );

    // ------------------------------------------------------------------------
    // Modifiers
    // ------------------------------------------------------------------------

    modifier onlyOwner() {
        require(msg.sender == owner, "EMPTY: not owner");
        _;
    }

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // ------------------------------------------------------------------------
    // Admin: mark known ecosystem nodes as occupied
    // ------------------------------------------------------------------------

    /**
     * @notice Tag an address as OCCUPIED, meaning it should never be treated
     *         as "empty space" by this locator.
     *
     * Example usage:
     * - tag all Pulse / Resonance / ZacEcho contracts
     * - tag any other core infra you consider part of the system
     */
    function tagOccupied(address target) external onlyOwner {
        require(target != address(0), "EMPTY: target zero");
        occupancyOf[target] = OccupancyType.Occupied;
        emit OccupiedTagged(target);
    }

    /**
     * @notice Clear the occupied tag for an address (back to None).
     */
    function clearOccupied(address target) external onlyOwner {
        require(target != address(0), "EMPTY: target zero");
        occupancyOf[target] = OccupancyType.None;
        // No event needed; optional
    }

    /**
     * @notice Transfer contract ownership.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "EMPTY: newOwner zero");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // ------------------------------------------------------------------------
    // Core: locate empty space
    // ------------------------------------------------------------------------

    /**
     * @notice Probe an address to see if it is "empty space" in the context
     *         of the Pulse ecosystem.
     *
     * Rules:
     * - If `target` is tagged as Occupied → ignore.
     * - If `target` has contract code (extcodesize > 0) → ignore.
     * - Otherwise → record/update as EMPTY SPACE.
     *
     * @param target      Address to probe.
     * @param contextTag  Arbitrary tag for your own reference:
     *                    e.g., bytes32("SCAN"), bytes32("TASK_101"), etc.
     */
    function probeSpace(address target, bytes32 contextTag) external {
        require(target != address(0), "EMPTY: target zero");
        require(contextTag != bytes32(0), "EMPTY: contextTag zero");

        // If this address is explicitly marked occupied, we skip.
        if (occupancyOf[target] == OccupancyType.Occupied) {
            return;
        }

        // If this address has contract code, it's not empty space.
        if (_hasCode(target)) {
            return;
        }

        // At this point, it's considered "empty space" for our purposes.
        EmptySpaceRecord storage rec = _empties[target];
        uint64 nowTs = uint64(block.timestamp);

        if (!rec.exists) {
            rec.exists = true;
            rec.firstTag = contextTag;
            rec.lastTag = contextTag;
            rec.firstSeen = nowTs;
            rec.lastSeen = nowTs;
            rec.observations = 1;

            emptyList.push(target);
        } else {
            rec.lastTag = contextTag;
            rec.lastSeen = nowTs;
            rec.observations += 1;
        }

        emit EmptySpaceObserved(
            msg.sender,
            target,
            contextTag,
            nowTs,
            rec.observations
        );
    }

    // ------------------------------------------------------------------------
    // Views
    // ------------------------------------------------------------------------

    /**
     * @notice Check if an address has ever been recorded as empty space.
     */
    function isEmptySpace(address target) external view returns (bool) {
        return _empties[target].exists;
    }

    /**
     * @notice Get the record for an empty-space address.
     *         Reverts if the address has never been recorded as empty.
     */
    function getEmptySpaceRecord(address target)
        external
        view
        returns (
            bool isEmpty,
            bytes32 firstTag,
            bytes32 lastTag,
            uint64 firstSeen,
            uint64 lastSeen,
            uint256 observations
        )
    {
        EmptySpaceRecord memory rec = _empties[target];
        require(rec.exists, "EMPTY: not recorded as empty");

        return (
            true,
            rec.firstTag,
            rec.lastTag,
            rec.firstSeen,
            rec.lastSeen,
            rec.observations
        );
    }

    /**
     * @notice Total number of unique empty-space addresses recorded.
     */
    function emptySpaceCount() external view returns (uint256) {
        return emptyList.length;
    }

    /**
     * @notice Get the full list of empty-space addresses.
     *         (Use carefully; this can grow over time.)
     */
    function getAllEmptySpace() external view returns (address[] memory) {
        return emptyList;
    }

    // ------------------------------------------------------------------------
    // Internal helpers
    // ------------------------------------------------------------------------

    function _hasCode(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
