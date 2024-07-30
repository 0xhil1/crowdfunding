// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { ICrowdFunding } from "src/interface/ICrowdFunding.sol";
import { Errors } from "src/utils/Errors.sol";

contract CrowdFunding is ICrowdFunding, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // @dev user deposit info
    mapping(address => uint256) public userDeposits;

    // @dev totally deposited amounts
    uint256 public totalDeposits;

    // @dev Treasury address which will receive the funds in `withdrawFunds`
    address public fundingTreasury;

    // Funding Goal info
    FundingGoal public fundGoal;

    constructor(address owner) Ownable(owner) {}

    modifier onlyGoalMet() {
        // caching for gas saving
        uint256 goalAmount = fundGoal.goalAmount;
        if (totalDeposits < goalAmount)
            revert Errors.FundingGoalNotMet(totalDeposits, goalAmount);

        _;
    }

    modifier notFullyFunded() {
        // Check fund amount
        if (totalDeposits >= fundGoal.goalAmount) revert Errors.FULLY_FUNDED();

        _;
    }

    /** 
      * @notice Deposit into this contract, specifying the exact number of fund token.
      * Only depositbale in case funding is not ended and 
      * `total_funded_amount < fund_goal`
      * @param amount Deposit amount
      */
    function deposit(uint256 amount) external payable notFullyFunded {
        // Check with deadline
        if (block.timestamp > fundGoal.deadline) revert Errors.FUND_ENDED();

        // check amount
        if (amount == 0) revert Errors.ZERO_AMOUNT();

        // Transfer tokens first
        address fundingToken = fundGoal.fundingToken;
        if (fundingToken == address(0)) {
            // if fundingToken is ETH then check with msg.value
            if (msg.value < amount) revert Errors.INVALID_PARAM();
        } else {
            // if fundingToken is ERC20, then just transfer
            IERC20(fundingToken).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
        }

        // update states
        userDeposits[msg.sender] = userDeposits[msg.sender] + amount;
        totalDeposits = totalDeposits + amount;

        // emit event
        emit Deposit(msg.sender, amount);
    }

    /** 
      * @notice Withdraw user's deposited fund token amounts
      * Only withdrawable in case funding is ended and 
      * `total_funded_amount < fund_goal`
      */
    function withdraw() external nonReentrant notFullyFunded {
        // Check fund is in progress
        if (block.timestamp < fundGoal.deadline) revert Errors.FUND_IN_PROGRESS();

        uint256 withdrawAmount = userDeposits[msg.sender];
        if (withdrawAmount == 0)
            revert Errors.ZERO_AMOUNT();

        // update state first - additional reentrant prevention
        delete userDeposits[msg.sender];

        address fundingToken = fundGoal.fundingToken;
        if (fundingToken == address(0)) {
            // if fundingToken is ETH
            (bool sent, ) = msg.sender.call{value: withdrawAmount}("");

            // check eth transfer successed
            if (!sent) revert Errors.ETHTransferFailed();
        } else {
            // if fundingToken is ERC20
            IERC20(fundingToken).safeTransfer(msg.sender, withdrawAmount);
        }

        // emit event
        emit Withdraw(msg.sender, withdrawAmount);
    }

    /** 
      * @notice Withdraw all deposited fund token amounts to treasury
      * Only available in case 
      * `total_funded_amount >= fund_goal`
      * Only owner can call this function
      */
    function withdrawFunds() external onlyOwner onlyGoalMet {
        // Check if treasury address is valid
        if (fundingTreasury == address(0))
            revert Errors.ZERO_ADDRESS();

        address fundingToken = fundGoal.fundingToken;
        if (fundingToken == address(0)) {
            // if fundingToken is ETH
            (bool sent, ) = fundingTreasury.call{value: totalDeposits}("");

            if (!sent) revert Errors.ETHTransferFailed();
        } else {
            // if fundingToken is ERC20
            IERC20(fundingToken).safeTransfer(fundingTreasury, totalDeposits);
        }
    }

    /** 
      * @notice Set funding goal info, and can set only once
      * Only owner can call this function
      * @param goalInfo Funding goal info
      */
    function setGoal(FundingGoal calldata goalInfo) external onlyOwner {
        // Check Goal already set;
        if (fundGoal.deadline != 0)
            revert Errors.FUND_IN_PROGRESS();
        
        // Check paramters
        if (goalInfo.deadline <= block.timestamp || goalInfo.goalAmount == 0)
            revert Errors.INVALID_PARAM();

        // update state
        fundGoal = goalInfo;

        // emit event
        emit SetFundGoal(goalInfo);
    }

    /** 
      * @notice Set treasury address
      * Only owner can call this function
      * @param treasury New treasury address
      */
    function setTreasury(address treasury) external onlyOwner {
        // Check treasury address is valid
        if (treasury == address(0))
            revert Errors.ZERO_ADDRESS();

        // update state
        fundingTreasury = treasury;

        // emit event
        emit SetTreasury(treasury);
    }
}
