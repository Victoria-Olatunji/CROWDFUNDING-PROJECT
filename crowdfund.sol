// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import"./crowdfundinterface.sol";
import"./time.sol";
contract crowdFund {
    //create an event named launch which comprises of id, creator, goal, startAt, endAt.
    event Lauch(
        uint id,
        address indexed creator,
        uint goal,
        uint32 startAt,
        uint32 endAt
    );

    event Cancel(
        uint id
    );

    event Pledge(
        uint indexed id,
        address indexed caller,
        uint amount
    );

    /*Class Work
    1. Create an event for Unpledge which has id, caller, amount.
    2. Create an event for Claim which has an id.
    3. Create an event for Refund which has an id that is not indexed, caller and amount.*/

    event Unpledge(
        uint indexed id,
        address indexed caller,
        uint amount
    );

    event Claim(
        uint id
    );

    event Refund(
        uint id,
        address indexed caller,
        uint amount
    );

    /*Class Work
    Create a struct named Campaign that has the following:
    creator, goal, pledged, startAt, endAt, and claimed which is a bool.*/

    struct Campaign {
        address creator; //address of the Campaign creator
        uint goal; //amount of tokens to be raised
        uint pledged; //total amount pledge
        uint32 startAt; //timestamp of when the campaign is starting
        uint32 endAt; //timestamp of when the campaign is ending
        bool claimed; //true if goal was reached and creator has claimed the tokens. by default initially false
    }

    IERC20 public immutable token; //making reference to the erc20 interface

    uint public count;//total count of campaign created and also used to generate id for new campaigns

    mapping(uint => Campaign) public campaigns; // mapping to capture campaign id

    mapping(uint => mapping(address => uint)) public pledgedAmount; // nested mapping to capture id of campaign
    // with the address of pledger and the amount pledged

    constructor(address _token){
        token = IERC20(_token);
    }

    function launch(uint _goal, uint32 _startAt, uint32 _endAt) external {
        require(_startAt >= block.timestamp, "startAt < now");
        require(_endAt >= _startAt, "endAt < startAt");
        require(_endAt <= block.timestamp + 90 days, "endAt > max duration");

        count += 1;

        campaigns[count] = Campaign(msg.sender, _goal, 0, _startAt, _endAt, false);

        emit Lauch(count, msg.sender, _goal, _startAt, _endAt);
        
    }

    function cancel(uint _id) external {
        Campaign memory campaign = campaigns[_id]; //indexing with an id in mapping campaigns
        //just fetching out id so not tampering and use use memory
        require(campaign.creator == msg.sender, "You are not the creator");
        require(block.timestamp < campaign.startAt, "The campaign has started");

        delete campaigns[_id];
        emit Cancel(_id);

    }

    function pledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id]; //indexing with an id in mapping campaigns, to update the struct we use storage
        require(block.timestamp >= campaign.startAt, "Campaign has not started");
        require(block.timestamp <= campaign.endAt, "Campaign has ended");
        campaign.pledged += _amount; //gave accesss to struct
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
        emit Pledge(_id, msg.sender, _amount);
    }

    function unpledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id]; //indexing with an id in mapping campaigns
        require(block.timestamp >= campaign.startAt, "Campaign has not started");
        require(block.timestamp <= campaign.endAt, "Campaign has ended");
        campaign.pledged -= _amount; //deducted from total supply
        pledgedAmount[_id][msg.sender] -= _amount; // deducted from the msg.sender
        token.transfer(msg.sender, _amount);
        emit Unpledge(_id, msg.sender, _amount);
    }

    function claim(uint _id) external {
        Campaign storage campaign = campaigns[_id]; //indexing with an id in mapping campaigns
        require(campaign.creator == msg.sender, "You are not the campaign creator");
        require(block.timestamp > campaign.endAt, "Campaign has not ended");
        require(campaign.pledged >= campaign.goal, "Pledge is less than goal");
        require(!campaign.claimed, "Campaign has been claimed");
        
        campaign.claimed = true;
        
        token.transfer(campaign.creator, campaign.pledged);

        emit Claim(_id);
    }

    function refund(uint _id) external {
        Campaign storage campaign = campaigns[_id]; //indexing with an id in mapping campaigns
        require(block.timestamp > campaign.endAt, "Campaign has not ended");
        require(campaign.pledged < campaign.goal, "Pledge is greater or equal to goal");
        
        uint balance = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, balance); // transfers the money to the person calling this function
        emit Refund(_id, msg.sender, balance);
    }
}