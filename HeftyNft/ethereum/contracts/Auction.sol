pragma solidity ^0.4.8;

//factory contract

contract AuctionFactory{
    address[] public deployedAuctions;

    function createAuction(address _owner, uint _startBlock, uint _endBlock, string _ipfsHash, uint _floorPrice) public{
       address newAuction =  new Auction(_owner, _startBlock, _endBlock, _ipfsHash, _floorPrice);
       deployedAuctions.push(newAuction);
    }

    function getDeployedAuctions() public view returns(address[]){
        return deployedAuctions;
    }
}

contract Auction {
    // static
    address public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;
    uint public floorPrice;
   // address public contr;


    // state
    bool public canceled;
    uint public highestBindingBid;
    address public highestBidder;
    mapping(address => uint256) public fundsByBidder;
    bool ownerHasWithdrawn;

    event LogBid(address bidder, uint bid, address highestBidder, uint highestBindingBid);
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
    event LogCanceled();

    function Auction(address _owner, uint _startBlock, uint _endBlock, string _ipfsHash, uint _floorPrice) {
        if (_startBlock >= _endBlock) { revert(); }
        if (_startBlock < block.number) { revert(); }
        if (_owner == 0) { revert(); }

        owner = _owner;
        startBlock = _startBlock;
        endBlock = _endBlock;
        ipfsHash = _ipfsHash;
        floorPrice = _floorPrice;
    }


    function placeBid()
        payable
        onlyAfterStart
        onlyBeforeEnd
        onlyNotCanceled
        onlyNotOwner
       returns (bool)
    {
        // reject payments of 0 ETH
        if (msg.value == 0 || msg.value <= floorPrice) { revert(); }

        // calculate the user's total bid based on the current amount they've sent to the contract
        // plus whatever has been sent with this transaction
        uint newBid =  msg.value;

        // if the user isn't even willing to overbid the highest binding bid, there's nothing for us
        // to do except revert the transaction.
        if (newBid <= highestBindingBid)  { revert(); }

        uint nextBid = (highestBindingBid * 10 /100) + highestBindingBid ;

        if (newBid < nextBid ) { revert (); }
        highestBidder.send(highestBindingBid);

        // grab the previous highest bid (before updating fundsByBidder, in case msg.sender is the
        // highestBidder and is just increasing their maximum bid).


            if (msg.sender != highestBidder) {
                highestBidder = msg.sender;

            }
            highestBindingBid = newBid;


        LogBid(msg.sender, newBid, highestBidder, highestBindingBid);
       return true;
    }


    function cancelAuction()
        onlyOwner
        onlyBeforeEnd
        onlyNotCanceled
        returns (bool success)
    {
        canceled = true;
        LogCanceled();

        address withdrawalAccount;
        uint withdrawalAmount;

        withdrawalAccount = highestBidder;
        withdrawalAmount = highestBindingBid;


        if (withdrawalAmount == 0) { revert(); }

        fundsByBidder[withdrawalAccount] -= withdrawalAmount;

        // send the funds
        if (!highestBidder.send(withdrawalAmount)) { revert(); }

        LogWithdrawal(highestBidder, withdrawalAccount, withdrawalAmount);


        return true;

    }

    function endAuction()  onlyOwner returns (bool success)
    {
        address withdrawalAccount;
        uint withdrawalAmount;

        endBlock = block.number;

        withdrawalAccount = owner;
        withdrawalAmount = highestBindingBid;
// logic for token transfer

        if (withdrawalAmount == 0) { revert(); }

        fundsByBidder[withdrawalAccount] -= withdrawalAmount;

        // send the funds
        if (!msg.sender.send(withdrawalAmount)) { revert(); }

        LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);

        return true;


    }


    modifier onlyOwner {
        if (msg.sender != owner) { revert(); }
        _;
    }

    modifier onlyNotOwner {
        if (msg.sender == owner) { revert(); }
        _;
    }

    modifier onlyAfterStart {
        if (block.number < startBlock) { revert(); }
        _;
    }

    modifier onlyBeforeEnd {
        if (block.number > endBlock) { revert(); }
        _;
    }

    modifier onlyNotCanceled {
        if (canceled) { revert(); }
        _;
    }

    modifier onlyEndedOrCanceled {
        if (block.number < endBlock && !canceled) { revert(); }
        _;
    }
}
