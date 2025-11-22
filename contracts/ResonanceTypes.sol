// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title ResonanceTypes
 * @notice Shared type definitions for the Resonance Registry system
 * @dev This file provides reusable struct definitions used across the registry contracts
 */

/**
 * @notice Resonance data structure
 * @dev Stores resonance score and last update timestamp for an entity
 * @param score The resonance score (0-1000 scale, representing 0.000-1.000)
 * @param lastUpdated The timestamp when this resonance was last updated (uint64 is safe until year 2106)
 */
struct Resonance {
    uint32 score;
    uint64 lastUpdated;
}
