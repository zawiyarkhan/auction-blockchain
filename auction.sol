// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract DecentralizedAuction {
    address public owner;
    uint public highestBindingBid;
    address public highestBidder;

    mapping(address => uint) public bids;
    address[] public participantAddresses;  // Initialize the participantAddresses array

    uint public minBidIncrement;

    bool public ended;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyBeforeEnd() {
        require(!ended, "Auction has already ended");
        _;
    }

    modifier onlyAfterEnd() {
        require(ended, "Auction has not ended yet");
        _;
    }

    constructor(uint _minBidIncrement) {
        owner = msg.sender;
        minBidIncrement = _minBidIncrement;
    }

    function placeBid() external payable onlyBeforeEnd {
        require(msg.value > bids[msg.sender], "Your bid must be higher than your previous bid");

        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid, "Your bid must be higher than the current highest bid");

        bids[msg.sender] = currentBid;

        if (currentBid > bids[highestBidder]) {
            highestBidder = msg.sender;
            highestBindingBid = currentBid;
        }

        // Update or add the participant address to the array
        bool participantExists = false;
        for (uint i = 0; i < participantAddresses.length; i++) {
            if (participantAddresses[i] == msg.sender) {
                participantExists = true;
                break;
            }
        }

        if (!participantExists) {
            participantAddresses.push(msg.sender);
        }
    }

    function finalizeAuction() external onlyOwner onlyAfterEnd {
        require(!ended, "Auction has already been finalized");
        ended = true;

        payable(owner).transfer(highestBindingBid);

        // Refund participants
        for (uint i = 0; i < participantAddresses.length; i++) {
            address withdrawer = participantAddresses[i];
            uint amount = bids[withdrawer];

            if (amount > 0) {
                bids[withdrawer] = 0;
                payable(withdrawer).transfer(amount);
            }
        }
    }

    function cancelAuction() external onlyOwner onlyBeforeEnd {
        require(!ended, "Auction has already been finalized");
        ended = true;

        // Refund participants
        for (uint i = 0; i < participantAddresses.length; i++) {
            address withdrawer = participantAddresses[i];
            uint amount = bids[withdrawer];

            if (amount > 0) {
                bids[withdrawer] = 0;
                payable(withdrawer).transfer(amount);
            }
        }
    }
}
