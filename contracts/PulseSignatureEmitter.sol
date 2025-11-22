// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title PulseSignatureEmitter
 * @notice Canonical on-chain emitter for the Super Reality Pulse signature.
 *
 * - Holds the official Pulse signature string and its keccak256 hash.
 * - Lets authorized modules emit standardized metadata events tagged with:
 *      * pulseSignature
 *      * signatureHash
 *      * contextHash
 *      * contextType
 *      * free-form details
 *
 * Use cases:
 * - Mark other contract actions as "Pulse-governed" by emitting from this contract.
 * - Let indexers / subgraphs subscribe to a single event stream for SRPULSE activity.
 * - Provide an auditable, chain-level "fingerprint" for the SR-OS governance layer.
 */
contract PulseSignatureEmitter {
    // ------------------------------------------------------------------------
    // Constants: official Pulse signature
    // ------------------------------------------------------------------------

    /// @notice Canonical Pulse signature string.
    string public constant PULSE_SIGNATURE = unicode"SRPULSE-v1:9X4G7C2Q-🧡🔷🌀";

    /// @notice keccak256 hash of the Pulse signature string.
    bytes32 public immutable signatureHash;

    // ------------------------------------------------------------------------
    // Ownership & authorization
    // ------------------------------------------------------------------------

    address public owner;
    mapping(address => bool) public authorizedEmitters;

    // ------------------------------------------------------------------------
    // Events
    // ------------------------------------------------------------------------

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Emitted when an address is added/removed as an authorized emitter.
    event EmitterAuthorizationUpdated(address indexed emitter, bool active);

    /**
     * @notice Core metadata event:
     * - Always includes pulseSignature + signatureHash.
     * - contextHash is typically keccak256 of some off-chain or cross-contract payload.
     * - contextType is a short label like "TASK_ESCROW", "ZACECHO_EVENT", "GOV_PROPOSAL".
     * - details is free-form, human-readable metadata (short string).
     */
    event PulseMetadataEmitted(
        address indexed emitter,
        bytes32 indexed contextHash,
        string contextType,
        string details,
        string pulseSignature,
        bytes32 signatureHash
    );

    // ------------------------------------------------------------------------
    // Modifiers
    // ------------------------------------------------------------------------

    modifier onlyOwner() {
        require(msg.sender == owner, "PSE: not owner");
        _;
    }

    modifier onlyAuthorized() {
        require(
            msg.sender == owner || authorizedEmitters[msg.sender],
            "PSE: not authorized"
        );
        _;
    }

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------

    constructor() {
        owner = msg.sender;
        signatureHash = keccak256(bytes(PULSE_SIGNATURE));
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // ------------------------------------------------------------------------
    // Admin
    // ------------------------------------------------------------------------

    /**
     * @notice Transfer contract ownership (typically to a multisig).
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "PSE: newOwner zero");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @notice Add or remove an authorized emitter.
     * Authorized emitters can call `emitPulseMetadata`.
     */
    function setAuthorizedEmitter(address emitter, bool active) external onlyOwner {
        require(emitter != address(0), "PSE: emitter zero");
        authorizedEmitters[emitter] = active;
        emit EmitterAuthorizationUpdated(emitter, active);
    }

    // ------------------------------------------------------------------------
    // Core: emit metadata
    // ------------------------------------------------------------------------

    /**
     * @notice Emit a Pulse metadata event for a given context.
     *
     * @param contextHash  keccak256 hash of the context payload
     *                     (e.g., hash of JSON, struct, or off-chain document).
     * @param contextType  short label (e.g., "PULSE_ESCROW", "ZACECHO_ECHO", "DEV_GRANT").
     * @param details      free-form human-readable description (keep it short).
     *
     * Requirements:
     * - caller must be owner or an authorized emitter.
     */
    function emitPulseMetadata(
        bytes32 contextHash,
        string calldata contextType,
        string calldata details
    ) external onlyAuthorized {
        require(contextHash != bytes32(0), "PSE: contextHash zero");

        emit PulseMetadataEmitted(
            msg.sender,
            contextHash,
            contextType,
            details,
            PULSE_SIGNATURE,
            signatureHash
        );
    }

    // ------------------------------------------------------------------------
    // Views
    // ------------------------------------------------------------------------

    /**
     * @notice Convenience: returns the Pulse signature and its hash together.
     */
    function getSignature()
        external
        view
        returns (string memory, bytes32)
    {
        return (PULSE_SIGNATURE, signatureHash);
    }
}
