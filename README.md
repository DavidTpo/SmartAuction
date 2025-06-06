# SmartAuction Contract

![Solidity](https://img.shields.io/badge/Solidity-^0.8.0-blue?logo=solidity)
![License](https://img.shields.io/badge/License-MIT-green)

An Ethereum smart contract for decentralized auctions with time extensions and automatic refunds.

## Contract Architecture

### State Variables

#### Core Parameters
| Variable | Type | Visibility | Description |
|----------|------|------------|-------------|
| `owner` | `address` | `public` | Contract deployer address |
| `startTime` | `uint256` | `public` | Auction start timestamp |
| `endTime` | `uint256` | `public` | Scheduled end timestamp |
| `initialDuration` | `uint256` | `public` | Initial duration (seconds) |

#### Auction State
| Variable | Type | Visibility | Description |
|----------|------|------------|-------------|
| `highestBid` | `uint256` | `public` | Current highest bid amount |
| `highestBidder` | `address` | `public` | Current leading bidder |
| `auctionEnded` | `bool` | `public` | Completion status flag |

#### Configuration
| Variable | Type | Visibility | Default | Description |
|----------|------|------------|---------|-------------|
| `minIncrementPercentage` | `uint256` | `public` | 5% | Minimum bid increase |
| `commissionPercentage` | `uint256` | `public` | 2% | Owner commission |

#### Data Structures
| Variable | Type | Visibility | Description |
|----------|------|------------|-------------|
| `bids` | `Bid[]` | `public` | Array of all bids |
| `bidIndices` | `mapping(address => uint256[])` | `public` | Bid indexes by address |
| `pendingReturns` | `mapping(address => uint256)` | `public` | Refundable balances |

### Struct Definition
```solidity
struct Bid {
    address bidder;     // Bidder's address
    uint256 amount;     // ETH amount in wei
    bool refunded;      // Refund status flag
}


## Events

| Event               | Parameters                                      | Description                          |
|---------------------|------------------------------------------------|--------------------------------------|
| **AuctionScheduled** | `(uint256 startTime, uint256 endTime)`         | Emitted when auction timings are set |
| **NewBid**          | `(address indexed bidder, uint256 amount, uint256 newEndTime)` | New valid bid placed |
| **AuctionEnded**    | `(address indexed winner, uint256 amount)`     | Auction successfully closed          |
| **Refund**          | `(address indexed bidder, uint256 amount)`     | Bid refund processed                |
| **PartialWithdrawal** | `(address indexed bidder, uint256 amount)`    | Excess funds withdrawn               |

## Function Reference

### Core Functions

#### `constructor(uint256 _initialDuration)`
- **Initializes** the auction contract  
- **Parameters**:  
  `_initialDuration`: Auction duration in seconds  
- **Effects**:  
  - Sets `owner` to deployer  
  - Stores `initialDuration`  

#### `scheduleAuction(uint256 _startTime)`
- *(OnlyOwner)* Sets auction start time  
- **Parameters**:  
  `_startTime`: Future timestamp to start  
- **Requirements**:  
  - Auction not already scheduled  
  - Start time must be future  

### Participant Functions

#### `placeBid() payable`
- Places new ETH bid  
- **Requirements**:  
  - Auction active  
  - Bid ≥ 5% higher than current  
- **Effects**:  
  - Extends auction if last 10 minutes  
  - Updates highest bid  
  - Emits `NewBid`  

#### `withdrawExcess()`
- Withdraws non-winning bids  
- **Effects**:  
  - Transfers eligible ETH  
  - Updates refund status  
  - Emits `PartialWithdrawal`  

### Finalization

#### `endAuction()`
- *(OnlyAfterAuctionEnded)* Finalizes auction  
- **Effects**:  
  - Transfers winning bid (minus 2% commission)  
  - Sets `auctionEnded` flag  
  - Emits `AuctionEnded`  

#### `claimRefund()`
- Claims refund for losing bids  
- **Requirements**:  
  - Auction ended  
  - Pending balance > 0  
- **Effects**:  
  - Transfers ETH  
  - Emits `Refund`

## Testing Notes

For development purposes, we used reduced time intervals (typically 5-15 minutes) to validate contract functionality efficiently while maintaining identical logical behavior to production timelines.

