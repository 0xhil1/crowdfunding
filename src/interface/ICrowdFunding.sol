// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ICrowdFunding {
    struct FundingGoal {
        address fundingToken;
        uint256 deadline;
        uint256 goalAmount;
    }

    event Deposit(address indexed user, uint256 amount);

    event Withdraw(address indexed user, uint256 amount);

    event WithdrawFunds(uint256 amount);

    event SetFundGoal(FundingGoal goal);

    event SetTreasury(address indexed treasury);

    function deposit(uint256 amount) external payable;

    function withdraw() external;
}