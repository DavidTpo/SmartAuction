// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SmartAuction
 * @dev Auction contract with time extension, partial refunds, and 2% commission  
 */
contract SmartAuction {
    // Structure to store information for each bid
    struct Bid {
        address bidder;
        uint256 amount;
        bool refunded;
    }
    
    // Auction parameters
    address public owner;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public initialDuration;
    uint256 public minIncrementPercentage = 5; // Minimum 5% increment
    uint256 public commissionPercentage = 2; // 2% commission
    uint256 public highestBid;
    address public highestBidder;
    bool public auctionEnded;
    
    // List of all bids
    Bid[] public bids;
    // Mapping of bids by participant
    mapping(address => uint256[]) public bidIndices;
    // Mapping of refundable balances
    mapping(address => uint256) public pendingReturns;
    
    // Events
    event NewBid(address indexed bidder, uint256 amount, uint256 newEndTime);
    event AuctionEnded(address indexed winner, uint256 amount);
    event Refund(address indexed bidder, uint256 amount);
    event PartialWithdrawal(address indexed bidder, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can execute this function");
        _;
    }
    
    modifier onlyWhileAuctionActive() {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Auction is not active");
        _;
    }
    
    modifier onlyAfterAuctionEnded() {
        require(block.timestamp > endTime, "Auction has not ended yet");
        _;
    }
    
    modifier onlyBeforeAuctionEnded() {
        require(block.timestamp <= endTime, "Auction has already ended");
        _;
    }
    
    /**
     * @dev Constructor that initializes the auction
     * @param _initialDuration Initial duration of the auction in seconds
     */
    constructor(uint256 _initialDuration) {
        owner = msg.sender;
        startTime = block.timestamp;
        initialDuration = _initialDuration;
        endTime = startTime + initialDuration;
        auctionEnded = false;
    }
    
    /**
     * @dev Function to place a bid
     */
    function placeBid() external payable onlyWhileAuctionActive {
        require(msg.value > 0, "Bid must be greater than zero");
        
        // Calculate the required minimum increment
        uint256 minBid = highestBid + (highestBid * minIncrementPercentage) / 100;
        
        // For the first bid, it only needs to be greater than zero
        if (highestBidder != address(0)) {
            require(msg.value >= minBid, "Bid must be at least 5% higher than the current highest bid");
        }
        
        // Register the bid
        bids.push(Bid({
            bidder: msg.sender,
            amount: msg.value,
            refunded: false
        }));
        bidIndices[msg.sender].push(bids.length - 1);
        
        // Update the highest bid
        if (msg.value > highestBid) {
            // Refund the previous highest bidder
            if (highestBidder != address(0)) {
                pendingReturns[highestBidder] += highestBid;
            }
            
            highestBid = msg.value;
            highestBidder = msg.sender;
            
            // Extend the auction if we're in the last 10 minutes
            if (block.timestamp >= endTime - 10 minutes) {
                endTime = block.timestamp + 10 minutes;
            }
        } else {
            // If not the highest bid, add to pending returns
            pendingReturns[msg.sender] += msg.value;
        }
        
        emit NewBid(msg.sender, msg.value, endTime);
    }
    
    /**
     * @dev Function to withdraw excess funds above the last bid
     */
    function withdrawExcess() external onlyWhileAuctionActive {
        uint256 totalBidAmount = 0;
        uint256[] storage indices = bidIndices[msg.sender];
        
        // Calculate total funds deposited by the user
        for (uint256 i = 0; i < indices.length; i++) {
            if (!bids[indices[i]].refunded) {
                totalBidAmount += bids[indices[i]].amount;
            }
        }
        
        // If not the highest bidder, can withdraw everything
        if (msg.sender != highestBidder) {
            require(pendingReturns[msg.sender] > 0, "No funds to withdraw");
            
            uint256 amount = pendingReturns[msg.sender];
            pendingReturns[msg.sender] = 0;
            
            // Mark bids as refunded
            for (uint256 i = 0; i < indices.length; i++) {
                if (!bids[indices[i]].refunded) {
                    bids[indices[i]].refunded = true;
                }
            }
            
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "Transfer failed");
            
            emit PartialWithdrawal(msg.sender, amount);
        } else {
            // If highest bidder, can only withdraw excess above highest bid
            require(totalBidAmount > highestBid, "No excess to withdraw");
            
            uint256 excess = totalBidAmount - highestBid;
            
            // Mark additional bids as refunded
            uint256 amountMarked = 0;
            for (uint256 i = 0; i < indices.length && amountMarked < excess; i++) {
                if (!bids[indices[i]].refunded && bids[indices[i]].amount <= (excess - amountMarked)) {
                    amountMarked += bids[indices[i]].amount;
                    bids[indices[i]].refunded = true;
                }
            }
            
            (bool success, ) = msg.sender.call{value: excess}("");
            require(success, "Transfer failed");
            
            emit PartialWithdrawal(msg.sender, excess);
        }
    }
    
    /**
     * @dev Ends the auction and distributes funds
     */
    function endAuction() external onlyAfterAuctionEnded {
        require(!auctionEnded, "Auction has already ended");
        
        auctionEnded = true;
        
        // Transfer winning amount to owner with 2% commission
        uint256 commission = (highestBid * commissionPercentage) / 100;
        uint256 ownerAmount = highestBid - commission;
        
        if (highestBidder != address(0)) {
            (bool success, ) = owner.call{value: ownerAmount}("");
            require(success, "Transfer to owner failed");
        }
        
        emit AuctionEnded(highestBidder, highestBid);
    }
    
    /**
     * @dev Allows participants to claim their refunds
     */
    function claimRefund() external {
        require(auctionEnded, "Auction has not ended");
        require(pendingReturns[msg.sender] > 0, "No funds to refund");
        
        uint256 amount = pendingReturns[msg.sender];
        pendingReturns[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Refund(msg.sender, amount);
    }
    
    /**
     * @dev Returns the winner and winning amount
     */
    function getWinner() external view returns (address, uint256) {
        return (highestBidder, highestBid);
    }
    
    /**
     * @dev Returns all bids made
     */
    function getAllBids() external view returns (Bid[] memory) {
        return bids;
    }
    
    /**
     * @dev Returns bids from a specific participant
     */
    function getBidsByAddress(address bidder) external view returns (Bid[] memory) {
        uint256[] storage indices = bidIndices[bidder];
        Bid[] memory userBids = new Bid[](indices.length);
        
        for (uint256 i = 0; i < indices.length; i++) {
            userBids[i] = bids[indices[i]];
        }
        
        return userBids;
    }
    
    /**
     * @dev Returns remaining auction time
     */
    function getTimeRemaining() external view returns (uint256) {
        if (block.timestamp >= endTime) {
            return 0;
        }
        return endTime - block.timestamp;
    }
}