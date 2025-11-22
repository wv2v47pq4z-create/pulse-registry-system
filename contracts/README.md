# EmptySpaceLocator Contract

## Overview

The `EmptySpaceLocator` contract is a specialized on-chain radar for identifying "empty space" - addresses that have no contract code and are not part of the Pulse / Resonance / ZacEcho ecosystem.

## Purpose

This contract is designed to:
- **Locate empty addresses**: Identify addresses without deployed contract code
- **Track ecosystem occupancy**: Maintain a registry of occupied (ecosystem) addresses
- **Record observations**: Track when and how often empty spaces are observed
- **Provide context**: Associate observations with custom tags for organizational purposes

## What This Contract Does NOT Do

- Track resonance, frequencies, or pulses
- Classify contracts by type (Pulse/Resonance/ZacEcho)
- Aggregate any global state other than "where is empty"

## Key Features

### 1. Owner Administration
- **Tag Occupied Addresses**: Owner can mark addresses as part of the ecosystem
- **Clear Tags**: Owner can remove occupancy tags
- **Transfer Ownership**: Standard ownership transfer functionality

### 2. Space Probing
- **Public Probing**: Anyone can probe addresses to check if they're empty
- **Smart Filtering**: Automatically ignores occupied and code-bearing addresses
- **Context Tags**: Associate observations with custom identifiers

### 3. Data Tracking
- **Observation Records**: Track first/last seen timestamps
- **Context History**: Record first and most recent context tags
- **Observation Count**: Track how many times an address was observed as empty

## Usage

### Deployment

Deploy the contract:
```solidity
EmptySpaceLocator locator = new EmptySpaceLocator();
```

The deployer becomes the owner automatically.

### Administrative Functions

#### Tag an address as occupied:
```solidity
locator.tagOccupied(0x1234...); // Mark as ecosystem address
```

#### Clear an occupancy tag:
```solidity
locator.clearOccupied(0x1234...); // Back to unknown state
```

#### Transfer ownership:
```solidity
locator.transferOwnership(0xNewOwner...);
```

### Public Functions

#### Probe for empty space:
```solidity
locator.probeSpace(
    0xTargetAddress...,
    bytes32("SCAN_BATCH_001")  // Custom context tag
);
```

**Behavior:**
- Reverts if target or contextTag is zero address/bytes32
- Ignores if target is tagged as Occupied
- Ignores if target has contract code
- Records/updates as empty space otherwise

#### Check if address is empty space:
```solidity
bool isEmpty = locator.isEmptySpace(0xAddress...);
```

#### Get empty space record:
```solidity
(
    bool isEmpty,
    bytes32 firstTag,
    bytes32 lastTag,
    uint64 firstSeen,
    uint64 lastSeen,
    uint256 observations
) = locator.getEmptySpaceRecord(0xAddress...);
```

#### Get empty space statistics:
```solidity
uint256 count = locator.emptySpaceCount();
address[] memory empties = locator.getAllEmptySpace();
```

## Events

### OwnershipTransferred
```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
```

### OccupiedTagged
```solidity
event OccupiedTagged(address indexed target);
```

### EmptySpaceObserved
```solidity
event EmptySpaceObserved(
    address indexed observer,
    address indexed target,
    bytes32 indexed contextTag,
    uint64 timestamp,
    uint256 totalObservations
);
```

## Example Workflow

1. **Deploy and configure:**
   ```solidity
   // Deploy
   EmptySpaceLocator locator = new EmptySpaceLocator();
   
   // Tag known ecosystem contracts
   locator.tagOccupied(pulseContract);
   locator.tagOccupied(resonanceContract);
   locator.tagOccupied(zacEchoContract);
   ```

2. **Scan for empty space:**
   ```solidity
   // Off-chain or on-chain scanner
   for (uint256 i = 0; i < addressesToScan.length; i++) {
       locator.probeSpace(
           addressesToScan[i],
           bytes32("SCAN_BATCH_001")
       );
   }
   ```

3. **Query results:**
   ```solidity
   // Get all empty addresses found
   address[] memory empties = locator.getAllEmptySpace();
   
   // Get details for specific address
   if (locator.isEmptySpace(someAddress)) {
       (
           bool isEmpty,
           bytes32 firstTag,
           bytes32 lastTag,
           uint64 firstSeen,
           uint64 lastSeen,
           uint256 observations
       ) = locator.getEmptySpaceRecord(someAddress);
   }
   ```

## Technical Details

### Storage Layout

- `owner`: Contract owner address
- `occupancyOf`: Mapping of address → OccupancyType (None or Occupied)
- `_empties`: Mapping of address → EmptySpaceRecord
- `emptyList`: Array of all recorded empty addresses

### Gas Considerations

- First observation of an address is more expensive (storage initialization + array push)
- Subsequent observations of same address are cheaper (only updates)
- `getAllEmptySpace()` can become expensive as the list grows

### Security Considerations

- Only owner can tag occupied addresses
- Zero address checks prevent invalid inputs
- No funds are held by this contract
- Read-only operations are gas-efficient

## Compilation

The contract requires Solidity ^0.8.21 and compiles without warnings or errors.

```bash
solcjs --bin --abi contracts/EmptySpaceLocator.sol
```

## License

MIT License - See LICENSE file for details
