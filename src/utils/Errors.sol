// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Errors {
    error ZERO_AMOUNT();

    error ZERO_ADDRESS();

    error INVALID_PARAM();

    error FUND_ENDED();

    error FUND_IN_PROGRESS();

    error FULLY_FUNDED();

    error ETHTransferFailed();

    error FundingGoalNotMet(uint256 totalDeposit, uint256 fundingGoal);
}
