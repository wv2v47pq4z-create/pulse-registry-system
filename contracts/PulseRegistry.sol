// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PulseRegistry
 * @dev Smart contract for registering and managing pulse audit results
 * Supports multiple modes: BAT, CREATOR, ARCHITECT
 */
contract PulseRegistry {
    
    // Enum for pulse types
    enum PulseType {
        RealityCheck,
        BatSignal,
        CreatorBeam,
        ArchitectBlueprint
    }
    
    // Enum for pulse status
    enum PulseStatus {
        PENDING,
        APPROVED,
        REJECTED
    }
    
    // Enum for operating modes
    enum Mode {
        BAT,
        CREATOR,
        ARCHITECT
    }
    
    // Struct for edge case scenarios
    struct EdgeCase {
        string scenario;
        string probability;
        string mitigation;
    }
    
    // Struct for pulse audit result
    struct PulseAuditResult {
        PulseType pulseType;
        string systemId;
        PulseStatus status;
        uint256 latencyP99;  // in milliseconds (scaled by 1000 for decimals)
        uint256 successRate; // in basis points (10000 = 100%)
        EdgeCase[] knownEdgeCases;
        bool identityCrisis;
        uint256 emptyCalories;
        string resonanceField;
        uint256 timestamp;
        address submitter;
    }
    
    // State variables
    Mode public currentMode;
    uint256 public pulseCounter;
    mapping(uint256 => PulseAuditResult) public pulses;
    mapping(address => uint256[]) public submitterPulses;
    
    // Events
    event PulseRegistered(
        uint256 indexed pulseId,
        PulseType pulseType,
        string systemId,
        PulseStatus status,
        address indexed submitter
    );
    
    event PulseBeamBroadcast(
        uint256 indexed pulseId,
        string resonanceField,
        uint256 timestamp
    );
    
    event ModeChanged(Mode oldMode, Mode newMode);
    
    // Constructor
    constructor() {
        currentMode = Mode.CREATOR; // Default mode
        pulseCounter = 0;
    }
    
    /**
     * @dev Register a new pulse audit result
     * @param _pulseType Type of pulse
     * @param _systemId System identifier
     * @param _status Initial status
     * @param _latencyP99 99th percentile latency (in microseconds, will be scaled)
     * @param _successRate Success rate in basis points
     * @param _resonanceField Resonance field description
     */
    function registerPulse(
        PulseType _pulseType,
        string memory _systemId,
        PulseStatus _status,
        uint256 _latencyP99,
        uint256 _successRate,
        string memory _resonanceField
    ) public returns (uint256) {
        require(_successRate <= 10000, "Success rate cannot exceed 100%");
        
        pulseCounter++;
        uint256 pulseId = pulseCounter;
        
        PulseAuditResult storage pulse = pulses[pulseId];
        pulse.pulseType = _pulseType;
        pulse.systemId = _systemId;
        pulse.status = _status;
        pulse.latencyP99 = _latencyP99;
        pulse.successRate = _successRate;
        pulse.identityCrisis = false; // eliminated by default
        pulse.emptyCalories = 0;
        pulse.resonanceField = _resonanceField;
        pulse.timestamp = block.timestamp;
        pulse.submitter = msg.sender;
        
        submitterPulses[msg.sender].push(pulseId);
        
        emit PulseRegistered(pulseId, _pulseType, _systemId, _status, msg.sender);
        emit PulseBeamBroadcast(pulseId, _resonanceField, block.timestamp);
        
        return pulseId;
    }
    
    /**
     * @dev Add an edge case to a pulse
     * @param _pulseId ID of the pulse
     * @param _scenario Description of the scenario
     * @param _probability Probability as string (e.g., "0.05%")
     * @param _mitigation Mitigation strategy
     */
    function addEdgeCase(
        uint256 _pulseId,
        string memory _scenario,
        string memory _probability,
        string memory _mitigation
    ) public {
        require(_pulseId > 0 && _pulseId <= pulseCounter, "Invalid pulse ID");
        require(pulses[_pulseId].submitter == msg.sender, "Not authorized");
        
        EdgeCase memory edgeCase = EdgeCase({
            scenario: _scenario,
            probability: _probability,
            mitigation: _mitigation
        });
        
        pulses[_pulseId].knownEdgeCases.push(edgeCase);
    }
    
    /**
     * @dev Update pulse status
     * @param _pulseId ID of the pulse
     * @param _status New status
     */
    function updatePulseStatus(uint256 _pulseId, PulseStatus _status) public {
        require(_pulseId > 0 && _pulseId <= pulseCounter, "Invalid pulse ID");
        require(pulses[_pulseId].submitter == msg.sender, "Not authorized");
        
        pulses[_pulseId].status = _status;
    }
    
    /**
     * @dev Change operating mode
     * @param _newMode New mode to switch to
     */
    function changeMode(Mode _newMode) public {
        Mode oldMode = currentMode;
        currentMode = _newMode;
        emit ModeChanged(oldMode, _newMode);
    }
    
    /**
     * @dev Get pulse details
     * @param _pulseId ID of the pulse
     */
    function getPulse(uint256 _pulseId) public view returns (
        PulseType pulseType,
        string memory systemId,
        PulseStatus status,
        uint256 latencyP99,
        uint256 successRate,
        bool identityCrisis,
        uint256 emptyCalories,
        string memory resonanceField,
        uint256 timestamp,
        address submitter
    ) {
        require(_pulseId > 0 && _pulseId <= pulseCounter, "Invalid pulse ID");
        PulseAuditResult storage pulse = pulses[_pulseId];
        
        return (
            pulse.pulseType,
            pulse.systemId,
            pulse.status,
            pulse.latencyP99,
            pulse.successRate,
            pulse.identityCrisis,
            pulse.emptyCalories,
            pulse.resonanceField,
            pulse.timestamp,
            pulse.submitter
        );
    }
    
    /**
     * @dev Get edge cases for a pulse
     * @param _pulseId ID of the pulse
     */
    function getEdgeCases(uint256 _pulseId) public view returns (EdgeCase[] memory) {
        require(_pulseId > 0 && _pulseId <= pulseCounter, "Invalid pulse ID");
        return pulses[_pulseId].knownEdgeCases;
    }
    
    /**
     * @dev Get all pulse IDs submitted by an address
     * @param _submitter Address of the submitter
     */
    function getSubmitterPulses(address _submitter) public view returns (uint256[] memory) {
        return submitterPulses[_submitter];
    }
    
    /**
     * @dev Get current mode as string
     */
    function getCurrentModeString() public view returns (string memory) {
        if (currentMode == Mode.BAT) return "BAT";
        if (currentMode == Mode.CREATOR) return "CREATOR";
        if (currentMode == Mode.ARCHITECT) return "ARCHITECT";
        return "UNKNOWN";
    }
}
