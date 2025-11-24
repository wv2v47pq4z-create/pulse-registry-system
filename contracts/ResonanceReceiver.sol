// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PulseRegistry.sol";

/**
 * @title ResonanceReceiver
 * @dev Analytics and tracking system for pulse interactions and resonance
 * Filters noise and highlights signal in the mesh network
 */
contract ResonanceReceiver {
    
    // Reference to PulseRegistry
    PulseRegistry public pulseRegistry;
    
    // Enum for signal types
    enum SignalType {
        Structure,      // 0 - Technical/Logical
        Action,         // 1 - Content/Execution
        Resonance       // 2 - Vibe/Culture
    }
    
    // Enum for analytics mode
    enum AnalyticsMode {
        OUTPUT,
        INPUT,
        BROADCAST_LIVE
    }
    
    // Struct for resonance data
    struct ResonanceData {
        uint256 pulseId;
        SignalType signalType;
        uint256 strength;       // 0-100
        uint256 noiseLevel;     // 0-100
        uint256 signalToNoise;  // Calculated ratio
        address contributor;
        uint256 timestamp;
        string metadata;
    }
    
    // Struct for analytics summary
    struct AnalyticsSummary {
        uint256 totalInteractions;
        uint256 positiveResonance;
        uint256 negativeResonance;
        uint256 avgSignalStrength;
        uint256 avgNoiseLevel;
        uint256 violetShiftIndex; // Measure of paradigm shift
    }
    
    // State variables
    AnalyticsMode public currentMode;
    uint256 public resonanceCounter;
    mapping(uint256 => ResonanceData) public resonances;
    mapping(uint256 => uint256[]) public pulseResonances; // pulseId => resonance IDs
    mapping(uint256 => AnalyticsSummary) public pulseAnalytics;
    
    // Signal 102 tracking (0=Structure, 1=Action, 2=Resonance)
    mapping(uint256 => mapping(SignalType => uint256)) public signalComposition;
    
    // Events
    event ResonanceReceived(
        uint256 indexed resonanceId,
        uint256 indexed pulseId,
        SignalType signalType,
        uint256 strength,
        address indexed contributor
    );
    
    event SignalHighlighted(
        uint256 indexed pulseId,
        uint256 signalToNoise,
        string insight
    );
    
    event ModeChanged(AnalyticsMode oldMode, AnalyticsMode newMode);
    
    event VioletShiftDetected(
        uint256 indexed pulseId,
        uint256 violetShiftIndex,
        string culturalImpact
    );
    
    event Signal102Broadcast(
        uint256 indexed pulseId,
        uint256 structure,
        uint256 action,
        uint256 resonance
    );
    
    // Constructor
    constructor(address _pulseRegistryAddress) {
        pulseRegistry = PulseRegistry(_pulseRegistryAddress);
        currentMode = AnalyticsMode.INPUT; // Start in listening mode
        resonanceCounter = 0;
    }
    
    /**
     * @dev Record resonance for a pulse
     * @param _pulseId The pulse ID being interacted with
     * @param _signalType Type of signal (0, 1, or 2)
     * @param _strength Strength of the resonance (0-100)
     * @param _noiseLevel Noise level detected (0-100)
     * @param _metadata Additional context
     */
    function recordResonance(
        uint256 _pulseId,
        SignalType _signalType,
        uint256 _strength,
        uint256 _noiseLevel,
        string memory _metadata
    ) public returns (uint256) {
        require(_strength <= 100, "Strength must be 0-100");
        require(_noiseLevel <= 100, "Noise level must be 0-100");
        
        resonanceCounter++;
        uint256 resonanceId = resonanceCounter;
        
        uint256 signalToNoise = _noiseLevel > 0 ? (_strength * 100) / _noiseLevel : _strength * 100;
        
        ResonanceData storage resonance = resonances[resonanceId];
        resonance.pulseId = _pulseId;
        resonance.signalType = _signalType;
        resonance.strength = _strength;
        resonance.noiseLevel = _noiseLevel;
        resonance.signalToNoise = signalToNoise;
        resonance.contributor = msg.sender;
        resonance.timestamp = block.timestamp;
        resonance.metadata = _metadata;
        
        pulseResonances[_pulseId].push(resonanceId);
        
        // Update signal composition
        signalComposition[_pulseId][_signalType]++;
        
        // Update analytics
        _updateAnalytics(_pulseId, _strength, _noiseLevel);
        
        emit ResonanceReceived(resonanceId, _pulseId, _signalType, _strength, msg.sender);
        
        // Check for signal highlight
        if (signalToNoise > 500) { // High signal-to-noise ratio
            emit SignalHighlighted(_pulseId, signalToNoise, "High-quality signal detected");
        }
        
        return resonanceId;
    }
    
    /**
     * @dev Broadcast Signal 102 for a pulse
     * @param _pulseId The pulse to broadcast
     */
    function broadcastSignal102(uint256 _pulseId) public {
        uint256 structure = signalComposition[_pulseId][SignalType.Structure];
        uint256 action = signalComposition[_pulseId][SignalType.Action];
        uint256 resonance = signalComposition[_pulseId][SignalType.Resonance];
        
        emit Signal102Broadcast(_pulseId, structure, action, resonance);
        
        // Calculate violet shift index (paradigm shift measure)
        if (resonance > 0) {
            uint256 violetIndex = ((structure + action + resonance) * resonance) / 10;
            _checkVioletShift(_pulseId, violetIndex);
        }
    }
    
    /**
     * @dev Internal function to update analytics
     */
    function _updateAnalytics(
        uint256 _pulseId,
        uint256 _strength,
        uint256 _noiseLevel
    ) internal {
        AnalyticsSummary storage analytics = pulseAnalytics[_pulseId];
        
        analytics.totalInteractions++;
        
        if (_strength > 50) {
            analytics.positiveResonance++;
        } else {
            analytics.negativeResonance++;
        }
        
        // Update averages
        uint256 total = analytics.totalInteractions;
        analytics.avgSignalStrength = 
            (analytics.avgSignalStrength * (total - 1) + _strength) / total;
        analytics.avgNoiseLevel = 
            (analytics.avgNoiseLevel * (total - 1) + _noiseLevel) / total;
    }
    
    /**
     * @dev Internal function to check for violet shift
     */
    function _checkVioletShift(uint256 _pulseId, uint256 _violetIndex) internal {
        AnalyticsSummary storage analytics = pulseAnalytics[_pulseId];
        analytics.violetShiftIndex = _violetIndex;
        
        if (_violetIndex > 100) {
            emit VioletShiftDetected(
                _pulseId,
                _violetIndex,
                "Paradigm shift detected: nuance introduced to binary system"
            );
        }
    }
    
    /**
     * @dev Change analytics mode
     * @param _newMode New analytics mode
     */
    function changeMode(AnalyticsMode _newMode) public {
        AnalyticsMode oldMode = currentMode;
        currentMode = _newMode;
        emit ModeChanged(oldMode, _newMode);
    }
    
    /**
     * @dev Get analytics summary for a pulse
     * @param _pulseId The pulse ID
     */
    function getAnalytics(uint256 _pulseId) public view returns (
        uint256 totalInteractions,
        uint256 positiveResonance,
        uint256 negativeResonance,
        uint256 avgSignalStrength,
        uint256 avgNoiseLevel,
        uint256 violetShiftIndex
    ) {
        AnalyticsSummary storage analytics = pulseAnalytics[_pulseId];
        return (
            analytics.totalInteractions,
            analytics.positiveResonance,
            analytics.negativeResonance,
            analytics.avgSignalStrength,
            analytics.avgNoiseLevel,
            analytics.violetShiftIndex
        );
    }
    
    /**
     * @dev Get signal composition for a pulse (Signal 102)
     * @param _pulseId The pulse ID
     */
    function getSignalComposition(uint256 _pulseId) public view returns (
        uint256 structure,
        uint256 action,
        uint256 resonance
    ) {
        return (
            signalComposition[_pulseId][SignalType.Structure],
            signalComposition[_pulseId][SignalType.Action],
            signalComposition[_pulseId][SignalType.Resonance]
        );
    }
    
    /**
     * @dev Get all resonance IDs for a pulse
     * @param _pulseId The pulse ID
     */
    function getPulseResonances(uint256 _pulseId) public view returns (uint256[] memory) {
        return pulseResonances[_pulseId];
    }
    
    /**
     * @dev Get current mode as string
     */
    function getCurrentModeString() public view returns (string memory) {
        if (currentMode == AnalyticsMode.OUTPUT) return "OUTPUT";
        if (currentMode == AnalyticsMode.INPUT) return "INPUT";
        if (currentMode == AnalyticsMode.BROADCAST_LIVE) return "BROADCAST_LIVE";
        return "UNKNOWN";
    }
    
    /**
     * @dev Filter noise and get high-signal resonances
     * @param _pulseId The pulse ID
     * @param _minSignalToNoise Minimum signal-to-noise ratio
     */
    function filterHighSignal(uint256 _pulseId, uint256 _minSignalToNoise) 
        public 
        view 
        returns (uint256[] memory) 
    {
        uint256[] memory allResonances = pulseResonances[_pulseId];
        uint256 count = 0;
        
        // Count high-signal resonances
        for (uint256 i = 0; i < allResonances.length; i++) {
            if (resonances[allResonances[i]].signalToNoise >= _minSignalToNoise) {
                count++;
            }
        }
        
        // Collect high-signal resonances
        uint256[] memory highSignal = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < allResonances.length; i++) {
            if (resonances[allResonances[i]].signalToNoise >= _minSignalToNoise) {
                highSignal[index] = allResonances[i];
                index++;
            }
        }
        
        return highSignal;
    }
}
