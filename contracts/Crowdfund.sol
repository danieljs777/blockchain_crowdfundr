//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./BadgeToken.sol";

contract Crowdfund
{

    uint256 private constant MIN_CONTRIB = 0.01 ether;
    uint private constant MAX_DAYS = 30;

    enum Status
    {
        Pending,
        GoalReached,
        Failed,
        Cancelled
    }

    address public immutable PROJECT_ADDRESS;
    address public immutable OWNER_ADDRESS;
    uint256 private immutable GOAL_AMOUNT;
    uint256 private immutable CREATED_AT;
    uint256 private immutable DEADLINE;

    string public name;
    
    Status public status;

    mapping(address => uint256) private contributions;
    mapping(address => uint256) private awardedTokens;
    address[] private contributors;

    modifier onlyOwner()
    {
        require(msg.sender == OWNER_ADDRESS);
        _;
    }

    modifier notFullyFunded()  
    {
        // console.log("-----------------------");
        // console.log("Goal    :", GOAL_AMOUNT);
        // console.log("Balance :", address(this).balance);

        require(status != Status.GoalReached, "Goal reached (mod)");
        //require(address(this).balance <= GOAL_AMOUNT, "Goal reached (mod)");
        _;
    }

    constructor(string memory _name, uint256 _goalAmount, address _ownerAddress) payable
    {
        name = _name;
        status = Status.Pending;

        OWNER_ADDRESS = _ownerAddress;
        GOAL_AMOUNT = _goalAmount;
        CREATED_AT = block.timestamp;
        DEADLINE = block.timestamp + 30 days;

        PROJECT_ADDRESS = address(this);

        // console.log("Balance ", address(this).balance);
        // console.log("Min Contrib ", MIN_CONTRIB);
       
    }

    function getBalance() public view
    {
        console.log("Balance :", address(this).balance);
    }

    function cancel() public onlyOwner
    {
        if(block.timestamp < DEADLINE)
        {
            status = Status.Cancelled;    
        }
    }

    function badgeReward(uint _amount) private
    {
        BadgeToken badge = new BadgeToken();
        awardedTokens[msg.sender] += _amount;

        for (uint256 i = 0; i < _amount; ++i)
        {
            badge.awardBadge(msg.sender);    
        }
        
    }    

    function getFunds(uint256 _amount) external payable onlyOwner
    {
        require(status == Status.GoalReached, "Goal not reached");
        require(_amount <= address(this).balance, "Cannot retrieve funds above balance");

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success);


    }

    function myBalance() external view returns (uint256)
    {
        // console.log("My Balance: ", contributions[msg.sender]);
        return contributions[msg.sender];
    }

    function withdraw(uint256 _amount) external
    {

        require(status == Status.Failed || status == Status.Cancelled, "Contract is not opened anymore");
        require(_amount <= contributions[msg.sender], "Withdraw is over your balance");
      
        // Checks totals from contributor
        if(contributions[msg.sender] > 0 && contributions[msg.sender] >= _amount)
        {
            contributions[msg.sender] -= _amount;

            (bool success, ) = msg.sender.call{value: _amount}("");
            require(success, "Withdraw failed");

        }

    }


    function contribute() external payable notFullyFunded
    {
        require(status != Status.Cancelled);
        require((msg.value >= MIN_CONTRIB), "Needs to be equal or more than minimal contribution");
        // require((address(this).balance <= GOAL_AMOUNT), "Goal reached (req)");

        console.log("getContr:", msg.value);

        if(block.timestamp > DEADLINE)
        {
            status = Status.Failed;

            this.withdraw(contributions[msg.sender]);

        }
        else
        {
            contributions[msg.sender] += msg.value

            contributors.push(msg.sender);

            // Checks if Project's balance reached its goals;
            if(address(this).balance >= GOAL_AMOUNT)
            {
                status = Status.GoalReached;
            }

            // Checks for awarding Badgets by ETHs acumulated

            uint badges = contributions[msg.sender] / 1 ether;

            console.log("Count badges", badges);
            console.log("Minted badges", awardedTokens[msg.sender]);

            if(badges > 0 && badges > awardedTokens[msg.sender])
            {
                badgeReward(badges - awardedTokens[msg.sender]);
            }
        }

        console.log("Goal    :", GOAL_AMOUNT);
        console.log("Balance :", address(this).balance);
        console.log("NFTs    :", awardedTokens[msg.sender]);

    }
}


