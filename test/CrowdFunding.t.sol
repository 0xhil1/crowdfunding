// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test } from "forge-std/Test.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20Errors } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { ICrowdFunding } from "src/interface/ICrowdFunding.sol";
import { Errors } from "src/utils/Errors.sol";
import { CrowdFunding } from "src/CrowdFunding.sol";
import { MintableToken } from "src/mock/MintableToken.sol";

contract CrowdFundingTestBase is Test {
    // generate users
    address public owner = makeAddr("owner");
    address public treasury = makeAddr("treasury");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    CrowdFunding public crowdFunding;

    function setUp() public virtual {
        crowdFunding = new CrowdFunding(owner);

        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
    }

    function setConfig(address tokenAddress) internal {
        // only owner can set treasury
        vm.startPrank(owner);
        crowdFunding.setTreasury(treasury);

        // setGoal
        ICrowdFunding.FundingGoal memory fundingGoal = ICrowdFunding.FundingGoal(
            tokenAddress, 
            block.timestamp + 1 days, // 1 day from now
            10e18 // 10 ETH or 10 Token
        );
        crowdFunding.setGoal(fundingGoal);
    }

    function test_setGoal_access() public {
        ICrowdFunding.FundingGoal memory fundingGoal = ICrowdFunding.FundingGoal(
            address(0), // ETH
            block.timestamp + 30 days, // 30 days from now
            100e18 // 100 ETH
        );

        // alice can not set goal
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice)
        );
        crowdFunding.setGoal(fundingGoal);

        // bob can not set goal
        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, bob)
        );
        crowdFunding.setGoal(fundingGoal);

        // only owner can set goal
        vm.startPrank(owner);

        // parameter check
        fundingGoal.deadline = block.timestamp;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.INVALID_PARAM.selector)
        );
        crowdFunding.setGoal(fundingGoal);

        fundingGoal.deadline = block.timestamp + 30 days;
        fundingGoal.goalAmount = 0;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.INVALID_PARAM.selector)
        );
        crowdFunding.setGoal(fundingGoal);

        // can set goal with correct parameter
        fundingGoal.goalAmount = 100e18;
        crowdFunding.setGoal(fundingGoal);
        ICrowdFunding.FundingGoal memory updatedGoal = crowdFunding.getFundGoal();
        assertEq(updatedGoal.fundingToken, fundingGoal.fundingToken);
        assertEq(updatedGoal.deadline, fundingGoal.deadline);
        assertEq(updatedGoal.goalAmount, fundingGoal.goalAmount);

        // Owner can not set goal again once it's set
        vm.expectRevert(
            abi.encodeWithSelector(Errors.FUND_IN_PROGRESS.selector)
        );
        crowdFunding.setGoal(fundingGoal);
    }

    function test_setTreasury_access() public {
        // alice can not set treasury
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice)
        );
        crowdFunding.setTreasury(treasury);

        // bob can not set treasury
        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, bob)
        );
        crowdFunding.setTreasury(treasury);

        // only owner can set treasury
        vm.startPrank(owner);
        crowdFunding.setTreasury(alice);
        assertEq(crowdFunding.fundingTreasury(), alice);

        crowdFunding.setTreasury(treasury);
        assertEq(crowdFunding.fundingTreasury(), treasury);
    }

    function test_withdrawFunds_access() public {
        // alice can not set treasury
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice)
        );
        crowdFunding.withdrawFunds();

        // bob can not set treasury
        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, bob)
        );
        crowdFunding.withdrawFunds();
    }
}

contract CrowdFundingETHTest is CrowdFundingTestBase {
    function test_deposit() public {
        // set config first with ETH
        setConfig(address(0));

        // test with `amount = 0`
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.ZERO_AMOUNT.selector)
        );
        crowdFunding.deposit(0);

        // test with `msg.value = 0`
        vm.expectRevert(
            abi.encodeWithSelector(Errors.INVALID_PARAM.selector)
        );
        crowdFunding.deposit(1e18);

        // test with correct parameters
        uint256 depositAmount = 1e18;
        {
            crowdFunding.deposit{value: depositAmount}(depositAmount);
            assertEq(crowdFunding.totalDeposits(), depositAmount);
            assertEq(crowdFunding.userDeposits(alice), depositAmount);
        }

        // bob also can do deposit
        {
            vm.startPrank(bob);
            uint256 bobDeposit = depositAmount * 2;
            crowdFunding.deposit{value: bobDeposit}(bobDeposit);
            assertEq(crowdFunding.totalDeposits(), depositAmount * 3);
            assertEq(crowdFunding.userDeposits(bob), bobDeposit);
        }

        // alice can deposit again
        {
            vm.startPrank(alice);
            crowdFunding.deposit{value: depositAmount * 5}(depositAmount * 5);
            assertEq(crowdFunding.totalDeposits(), depositAmount * 8);
            assertEq(crowdFunding.userDeposits(alice), depositAmount * 6);
        }

        // bob can deposit again
        {
            vm.startPrank(bob);
            crowdFunding.deposit{value: depositAmount * 3}(depositAmount * 3);
            assertEq(crowdFunding.totalDeposits(), depositAmount * 11);
            assertEq(crowdFunding.userDeposits(bob), depositAmount * 5);
        }

        // Alice and Bob can not deposit again as fully funded
        {
            vm.startPrank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FULLY_FUNDED.selector)
            );
            crowdFunding.deposit{value: depositAmount}(depositAmount);

            vm.startPrank(bob);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FULLY_FUNDED.selector)
            );
            crowdFunding.deposit{value: depositAmount}(depositAmount);
        }
    }

    function test_deposit_deadline() public {
        // set config first with ETH
        setConfig(address(0));

        // test with correct parameters
        uint256 depositAmount = 1e18;
        vm.startPrank(alice);
        {
            crowdFunding.deposit{value: depositAmount}(depositAmount);
            assertEq(crowdFunding.totalDeposits(), depositAmount);
            assertEq(crowdFunding.userDeposits(alice), depositAmount);
        }

        // deadline not passed yet
        vm.warp(block.timestamp + 1 days);

        // Alice and Bob can deposit still
        {
            crowdFunding.deposit{value: depositAmount}(depositAmount);

            vm.startPrank(bob);
            crowdFunding.deposit{value: depositAmount}(depositAmount);
        }

        // deadline passed
        vm.warp(block.timestamp + 1 days + 1);

        // Alice and Bob can not deposit though not got met as deadline passed
        {
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_ENDED.selector)
            );
            crowdFunding.deposit{value: depositAmount}(depositAmount);

            vm.startPrank(bob);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_ENDED.selector)
            );
            crowdFunding.deposit{value: depositAmount}(depositAmount);
        }
    }

    function test_withdraw_deadline() public {
        // set config first with ETH
        setConfig(address(0));

        // Alice and Bob deposits
        uint256 depositAmount = 1e18;
        {
            vm.startPrank(alice);
            crowdFunding.deposit{value: depositAmount}(depositAmount);

            vm.startPrank(bob);
            crowdFunding.deposit{value: depositAmount}(depositAmount);
        }

        // Alice and Bob can not withdraw
        {
            vm.startPrank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_IN_PROGRESS.selector)
            );
            crowdFunding.withdraw();

            vm.startPrank(bob);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_IN_PROGRESS.selector)
            );
            crowdFunding.withdraw();
        }

        // deadline not passed
        vm.warp(block.timestamp + 1 days);

        // Alice and Bob can not withdraw as funding deadline not ended
        {
            vm.startPrank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_IN_PROGRESS.selector)
            );
            crowdFunding.withdraw();

            vm.startPrank(bob);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_IN_PROGRESS.selector)
            );
            crowdFunding.withdraw();
        }

        // Alice depoist more
        {
            vm.startPrank(alice);
            crowdFunding.deposit{value: depositAmount * 10}(depositAmount * 10);
        }

        // deadline passed
        vm.warp(block.timestamp + 1 days + 1);

        // Alice and Bob can not withdraw as fully funded
        {
            vm.startPrank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FULLY_FUNDED.selector)
            );
            crowdFunding.withdraw();

            vm.startPrank(bob);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FULLY_FUNDED.selector)
            );
            crowdFunding.withdraw();
        }
    }

    function test_withdraw() public {
        // set config first with ETH
        setConfig(address(0));

        // Alice and Bob deposits
        uint256 depositAmount = 1e18;
        {
            vm.startPrank(alice);
            crowdFunding.deposit{value: depositAmount}(depositAmount);

            vm.startPrank(bob);
            crowdFunding.deposit{value: depositAmount}(depositAmount);
        }

        // Alice and Bob can not withdraw
        {
            vm.startPrank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_IN_PROGRESS.selector)
            );
            crowdFunding.withdraw();

            vm.startPrank(bob);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_IN_PROGRESS.selector)
            );
            crowdFunding.withdraw();
        }

        // deadline not passed
        vm.warp(block.timestamp + 1 days);

        // Alice and Bob can not withdraw as funding deadline not ended
        {
            vm.startPrank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_IN_PROGRESS.selector)
            );
            crowdFunding.withdraw();

            vm.startPrank(bob);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_IN_PROGRESS.selector)
            );
            crowdFunding.withdraw();
        }

        // Alice and Bob depoist more
        {
            vm.startPrank(alice);
            crowdFunding.deposit{value: depositAmount * 3}(depositAmount * 3);

            vm.startPrank(bob);
            crowdFunding.deposit{value: depositAmount * 4}(depositAmount * 4);
        }

        // deadline passed
        vm.warp(block.timestamp + 1 days + 1);

        // Alice and Bob can withdraw
        {
            vm.startPrank(alice);
            uint256 beforeAlice = alice.balance;
            crowdFunding.withdraw();
            assertEq(crowdFunding.userDeposits(alice), 0);
            assertEq(alice.balance, beforeAlice + depositAmount * 4);

            vm.startPrank(bob);
            uint256 beforeBob = bob.balance;
            crowdFunding.withdraw();
            assertEq(crowdFunding.userDeposits(bob), 0);
            assertEq(bob.balance, beforeBob + depositAmount * 5);
        }

        // Alice and Bob can not withdraw again
        {
            vm.startPrank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.ZERO_AMOUNT.selector)
            );
            crowdFunding.withdraw();

            vm.startPrank(bob);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.ZERO_AMOUNT.selector)
            );
            crowdFunding.withdraw();
        }
    }

    function test_withdrawFunds_fail() public {
        // set config first with ETH
        setConfig(address(0));

        ICrowdFunding.FundingGoal memory goalInfo = crowdFunding.getFundGoal();

        // Alice and Bob deposits
        uint256 depositAmount = 1e18;
        {
            vm.startPrank(alice);
            crowdFunding.deposit{value: depositAmount}(depositAmount);

            vm.startPrank(bob);
            crowdFunding.deposit{value: depositAmount}(depositAmount);
        }

        // owner can not `withdrawFunds` as not fully_funded
        {
            vm.startPrank(owner);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FundingGoalNotMet.selector, depositAmount * 2, goalInfo.goalAmount)
            );
            crowdFunding.withdrawFunds();
        }

        // Alice and Bob deposits more
        {
            vm.startPrank(alice);
            crowdFunding.deposit{value: depositAmount}(depositAmount);

            vm.startPrank(bob);
            crowdFunding.deposit{value: depositAmount}(depositAmount);
        }

        // deadline passed
        vm.warp(block.timestamp + 1 days + 1);

        // Owner still can not `withdrawFunds`
        {
            vm.startPrank(owner);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FundingGoalNotMet.selector, depositAmount * 4, goalInfo.goalAmount)
            );
            crowdFunding.withdrawFunds();
        }
    }

    function test_withdrawFunds_success() public {
        // set config first with ETH
        setConfig(address(0));

        ICrowdFunding.FundingGoal memory goalInfo = crowdFunding.getFundGoal();

        // Alice and Bob deposits
        uint256 depositAmount = 1e18;
        {
            vm.startPrank(alice);
            crowdFunding.deposit{value: depositAmount}(depositAmount);

            vm.startPrank(bob);
            crowdFunding.deposit{value: depositAmount}(depositAmount);
        }

        // owner can not `withdrawFunds` as not fully_funded
        {
            vm.startPrank(owner);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FundingGoalNotMet.selector, depositAmount * 2, goalInfo.goalAmount)
            );
            crowdFunding.withdrawFunds();
        }

        // Alice and Bob deposits more
        {
            vm.startPrank(alice);
            crowdFunding.deposit{value: depositAmount * 4}(depositAmount * 4);

            vm.startPrank(bob);
            crowdFunding.deposit{value: depositAmount * 4}(depositAmount * 4);
        }

        // deadline passed
        vm.warp(block.timestamp + 1 days + 1);

        // Alice and Bob can not withdraw as fully_funded
        {
            vm.startPrank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FULLY_FUNDED.selector)
            );
            crowdFunding.withdraw();

            vm.startPrank(bob);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FULLY_FUNDED.selector)
            );
            crowdFunding.withdraw();
        }

        // Owner can `withdrawFunds`
        {
            vm.startPrank(owner);
            crowdFunding.withdrawFunds();
            assertEq(treasury.balance, depositAmount * 10);
        }
    }
}

contract CrowdFundingERC20Test is CrowdFundingTestBase {
    address tokenAddr;

    MintableToken internal fundingToken;

    function setUp() public override {
        super.setUp();

        fundingToken = new MintableToken("Funding Token", "FTT");
        tokenAddr = address(fundingToken);

        // mint tokens to alice and bob
        uint256 mintAmount = 10e18;
        fundingToken.mint(alice, mintAmount);
        fundingToken.mint(bob, mintAmount);

        // approve tokens first
        vm.startPrank(alice);
        fundingToken.approve(address(crowdFunding), mintAmount);

        vm.startPrank(bob);
        fundingToken.approve(address(crowdFunding), mintAmount);
    }

    function test_deposit() public {
        // set config first with ETH
        setConfig(tokenAddr);

        // test with `amount = 0`
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.ZERO_AMOUNT.selector)
        );
        crowdFunding.deposit(0);

        // test with `100 FTT`
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, address(crowdFunding), 10e18, 100e18)
        );
        crowdFunding.deposit(100e18);

        // test with correct parameters
        uint256 depositAmount = 1e18;
        {
            crowdFunding.deposit(depositAmount);
            assertEq(crowdFunding.totalDeposits(), depositAmount);
            assertEq(crowdFunding.userDeposits(alice), depositAmount);
        }

        // bob also can do deposit
        {
            vm.startPrank(bob);
            uint256 bobDeposit = depositAmount * 2;
            crowdFunding.deposit(bobDeposit);
            assertEq(crowdFunding.totalDeposits(), depositAmount * 3);
            assertEq(crowdFunding.userDeposits(bob), bobDeposit);
        }

        // alice can deposit again
        {
            vm.startPrank(alice);
            crowdFunding.deposit(depositAmount * 5);
            assertEq(crowdFunding.totalDeposits(), depositAmount * 8);
            assertEq(crowdFunding.userDeposits(alice), depositAmount * 6);
        }

        // bob can deposit again
        {
            vm.startPrank(bob);
            crowdFunding.deposit(depositAmount * 3);
            assertEq(crowdFunding.totalDeposits(), depositAmount * 11);
            assertEq(crowdFunding.userDeposits(bob), depositAmount * 5);
        }

        // Alice and Bob can not deposit again as fully funded
        {
            vm.startPrank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FULLY_FUNDED.selector)
            );
            crowdFunding.deposit(depositAmount);

            vm.startPrank(bob);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FULLY_FUNDED.selector)
            );
            crowdFunding.deposit(depositAmount);
        }
    }

    function test_deposit_deadline() public {
        // set config first with ETH
        setConfig(tokenAddr);

        // test with correct parameters
        uint256 depositAmount = 1e18;
        vm.startPrank(alice);
        {
            crowdFunding.deposit(depositAmount);
            assertEq(crowdFunding.totalDeposits(), depositAmount);
            assertEq(crowdFunding.userDeposits(alice), depositAmount);
        }

        // deadline not passed yet
        vm.warp(block.timestamp + 1 days);

        // Alice and Bob can deposit still
        {
            crowdFunding.deposit(depositAmount);

            vm.startPrank(bob);
            crowdFunding.deposit(depositAmount);
        }

        // deadline passed
        vm.warp(block.timestamp + 1 days + 1);

        // Alice and Bob can not deposit though not got met as deadline passed
        {
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_ENDED.selector)
            );
            crowdFunding.deposit(depositAmount);

            vm.startPrank(bob);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_ENDED.selector)
            );
            crowdFunding.deposit(depositAmount);
        }
    }

    function test_withdraw_deadline() public {
        // set config first with ETH
        setConfig(tokenAddr);

        // Alice and Bob deposits
        uint256 depositAmount = 1e18;
        {
            vm.startPrank(alice);
            crowdFunding.deposit(depositAmount);

            vm.startPrank(bob);
            crowdFunding.deposit(depositAmount);
        }

        // Alice and Bob can not withdraw
        {
            vm.startPrank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_IN_PROGRESS.selector)
            );
            crowdFunding.withdraw();

            vm.startPrank(bob);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_IN_PROGRESS.selector)
            );
            crowdFunding.withdraw();
        }

        // deadline not passed
        vm.warp(block.timestamp + 1 days);

        // Alice and Bob can not withdraw as funding deadline not ended
        {
            vm.startPrank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_IN_PROGRESS.selector)
            );
            crowdFunding.withdraw();

            vm.startPrank(bob);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_IN_PROGRESS.selector)
            );
            crowdFunding.withdraw();
        }

        // Alice depoist more
        {
            vm.startPrank(alice);
            crowdFunding.deposit(depositAmount * 9);
        }

        // deadline passed
        vm.warp(block.timestamp + 1 days + 1);

        // Alice and Bob can not withdraw as fully funded
        {
            vm.startPrank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FULLY_FUNDED.selector)
            );
            crowdFunding.withdraw();

            vm.startPrank(bob);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FULLY_FUNDED.selector)
            );
            crowdFunding.withdraw();
        }
    }

    function test_withdraw() public {
        // set config first with ETH
        setConfig(tokenAddr);

        // Alice and Bob deposits
        uint256 depositAmount = 1e18;
        {
            vm.startPrank(alice);
            crowdFunding.deposit(depositAmount);

            vm.startPrank(bob);
            crowdFunding.deposit(depositAmount);
        }

        // Alice and Bob can not withdraw
        {
            vm.startPrank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_IN_PROGRESS.selector)
            );
            crowdFunding.withdraw();

            vm.startPrank(bob);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_IN_PROGRESS.selector)
            );
            crowdFunding.withdraw();
        }

        // deadline not passed
        vm.warp(block.timestamp + 1 days);

        // Alice and Bob can not withdraw as funding deadline not ended
        {
            vm.startPrank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_IN_PROGRESS.selector)
            );
            crowdFunding.withdraw();

            vm.startPrank(bob);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FUND_IN_PROGRESS.selector)
            );
            crowdFunding.withdraw();
        }

        // Alice and Bob depoist more
        {
            vm.startPrank(alice);
            crowdFunding.deposit(depositAmount * 3);

            vm.startPrank(bob);
            crowdFunding.deposit(depositAmount * 4);
        }

        // deadline passed
        vm.warp(block.timestamp + 1 days + 1);

        // Alice and Bob can withdraw
        {
            vm.startPrank(alice);
            uint256 beforeAlice = fundingToken.balanceOf(alice);
            crowdFunding.withdraw();
            assertEq(crowdFunding.userDeposits(alice), 0);
            assertEq(fundingToken.balanceOf(alice), beforeAlice + depositAmount * 4);

            vm.startPrank(bob);
            uint256 beforeBob = fundingToken.balanceOf(bob);
            crowdFunding.withdraw();
            assertEq(crowdFunding.userDeposits(bob), 0);
            assertEq(fundingToken.balanceOf(bob), beforeBob + depositAmount * 5);
        }

        // Alice and Bob can not withdraw again
        {
            vm.startPrank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.ZERO_AMOUNT.selector)
            );
            crowdFunding.withdraw();

            vm.startPrank(bob);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.ZERO_AMOUNT.selector)
            );
            crowdFunding.withdraw();
        }
    }

    function test_withdrawFunds_fail() public {
        // set config first with ETH
        setConfig(tokenAddr);

        ICrowdFunding.FundingGoal memory goalInfo = crowdFunding.getFundGoal();

        // Alice and Bob deposits
        uint256 depositAmount = 1e18;
        {
            vm.startPrank(alice);
            crowdFunding.deposit(depositAmount);

            vm.startPrank(bob);
            crowdFunding.deposit(depositAmount);
        }

        // owner can not `withdrawFunds` as not fully_funded
        {
            vm.startPrank(owner);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FundingGoalNotMet.selector, depositAmount * 2, goalInfo.goalAmount)
            );
            crowdFunding.withdrawFunds();
        }

        // Alice and Bob deposits more
        {
            vm.startPrank(alice);
            crowdFunding.deposit(depositAmount);

            vm.startPrank(bob);
            crowdFunding.deposit(depositAmount);
        }

        // deadline passed
        vm.warp(block.timestamp + 1 days + 1);

        // Owner still can not `withdrawFunds`
        {
            vm.startPrank(owner);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FundingGoalNotMet.selector, depositAmount * 4, goalInfo.goalAmount)
            );
            crowdFunding.withdrawFunds();
        }
    }

    function test_withdrawFunds_success() public {
        // set config first with ETH
        setConfig(tokenAddr);

        ICrowdFunding.FundingGoal memory goalInfo = crowdFunding.getFundGoal();

        // Alice and Bob deposits
        uint256 depositAmount = 1e18;
        {
            vm.startPrank(alice);
            crowdFunding.deposit(depositAmount);

            vm.startPrank(bob);
            crowdFunding.deposit(depositAmount);
        }

        // owner can not `withdrawFunds` as not fully_funded
        {
            vm.startPrank(owner);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FundingGoalNotMet.selector, depositAmount * 2, goalInfo.goalAmount)
            );
            crowdFunding.withdrawFunds();
        }

        // Alice and Bob deposits more
        {
            vm.startPrank(alice);
            crowdFunding.deposit(depositAmount * 4);

            vm.startPrank(bob);
            crowdFunding.deposit(depositAmount * 4);
        }

        // deadline passed
        vm.warp(block.timestamp + 1 days + 1);

        // Alice and Bob can not withdraw as fully_funded
        {
            vm.startPrank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FULLY_FUNDED.selector)
            );
            crowdFunding.withdraw();

            vm.startPrank(bob);
            vm.expectRevert(
                abi.encodeWithSelector(Errors.FULLY_FUNDED.selector)
            );
            crowdFunding.withdraw();
        }

        // Owner can `withdrawFunds`
        {
            vm.startPrank(owner);
            crowdFunding.withdrawFunds();
            assertEq(fundingToken.balanceOf(treasury), depositAmount * 10);
        }
    }
}