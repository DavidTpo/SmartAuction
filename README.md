# SmartAuction Contract

![Solidity](https://img.shields.io/badge/Solidity-0.8.30-blue?logo=solidity)
![License](https://img.shields.io/badge/License-MIT-green)
![Optimized](https://img.shields.io/badge/Optimized-Gas%20Efficient-brightgreen)

An advanced Ethereum auction contract featuring time extensions, automatic refunds, and commission management.

## Contract Architecture

### State Variables

#### Core Parameters
| Variable | Type | Visibility | Description |
|----------|------|------------|-------------|
| `owner` | `address` | `public` | Contract deployer (immutable) |
| `startTime` | `uint256` | `public` | Auction start timestamp (immutable) |
| `endTime` | `uint256` | `public` | Current end timestamp |
| `initialDuration` | `uint256` | `public` | Initial duration in seconds (immutable) |

#### Auction State
| Variable | Type | Visibility | Description |
|----------|------|------------|-------------|
| `highestBid` | `uint256` | `public` | Current winning bid amount |
| `highestBidder` | `address` | `public` | Current winning address |
| `isAuctionEnded` | `bool` | `public` | Finalization status flag |

#### Configuration Constants
| Constant | Type | Value | Description |
|----------|------|-------|-------------|
| `MIN_INCREMENT_PCT` | `uint256` | 5% | Minimum bid increase percentage |
| `COMMISSION_PCT` | `uint256` | 2% | Owner commission percentage |

#### Data Structures
| Variable | Type | Description |
|----------|------|-------------|
| `bids` | `Bid[]` | Historical record of all bids |
| `bidIndices` | `mapping(address => uint256[])` | Bid indexes per address |
| `pendingReturns` | `mapping(address => uint256)` | Refundable amounts per bidder |

### Struct Definition
```solidity
struct Bid {
    address bidder;     // Participant's address
    uint256 amount;     // Bid amount in wei
    bool refunded;      // Flag indicating if refunded
}

## Function Reference

### Core Functions

#### `constructor(uint256 _initialDuration)`
- **Initializes** auction parameters  
- **Parameters**:  
  `_initialDuration`: Initial auction duration in seconds  
- **Effects**:  
  - Sets immutable `owner` to deployer  
  - Records `startTime` as block timestamp  
  - Calculates initial `endTime`  

### Participant Functions

#### `placeBid() payable`
- **Processes** new ETH bid  
- **Requirements**:  
  - Auction must be active (`whenActive`)  
  - Bid value > 0  
  - For non-first bids: ≥5% higher than current  
- **Effects**:  
  - Extends auction by 10 minutes if in final 10 minutes  
  - Updates highest bid and bidder  
  - Records bid in history  
  - Emits `NewBid`  

#### `withdrawExcess()`
- **Withdraws** non-winning bid amounts  
- **Requirements**:  
  - Auction active (`whenActive`)  
  - Available funds to withdraw  
- **Effects**:  
  - For non-winners: withdraws all eligible funds  
  - For current winner: withdraws only excess above winning bid  
  - Updates refund statuses  
  - Emits `PartialWithdrawal`  

### Finalization Functions

#### `endAuction()`
- **Finalizes** the auction  
- **Requirements**:  
  - Auction time has ended  
  - Not already finalized  
- **Effects**:  
  - Transfers winning amount (minus 2% commission) to owner  
  - Sets `isAuctionEnded` flag  
  - Emits `AuctionEnded`  

#### `claimRefund()`
- **Processes** refunds for losing bidders  
- **Requirements**:  
  - Auction ended (`whenEnded`)  
  - Pending balance available (`hasRefunds`)  
- **Effects**:  
  - Transfers refund amount to caller  
  - Updates pending returns  
  - Emits `Refund`  

## View Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `getWinner()` | `(address, uint256)` | Returns winner and winning amount |
| `getAllBids()` | `Bid[]` | Returns complete bid history |
| `getBidsByAddress(address)` | `Bid[]` | Returns bids for specific address |
| `getTimeRemaining()` | `uint256` | Returns seconds until auction end |

## Development Notes

### Testing Methodology
- Used shortened time intervals (5-15 minutes) for efficient validation
- Verified all edge cases:
  - Last-minute bid extensions
  - Exact 5% increment bids
  - Multiple concurrent withdrawals
  - Commission calculation accuracy

### Optimization Highlights
- Immutable variables for gas efficiency
- Cached storage reads in loops
- Pre-increment counters in unchecked blocks
- Short error messages to reduce bytecode size
- Pull pattern for secure refund handling

### Deployment Checklist
1. Verify constructor parameters
2. Test with reduced time intervals
3. Confirm commission calculations
4. Validate refund functionality
5. Verify event emissions

## Testing Notes

For development purposes, we used reduced time intervals (typically 5-15 minutes) to validate contract functionality efficiently while maintaining identical logical behavior to production timelines.

