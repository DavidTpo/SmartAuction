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

## Testing Notes

For development purposes, we used reduced time intervals (typically 5-15 minutes) to validate contract functionality efficiently while maintaining identical logical behavior to production timelines.

