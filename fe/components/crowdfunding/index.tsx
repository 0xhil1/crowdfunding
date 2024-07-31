import React, { useEffect, useState } from "react";
import { BigNumber, utils } from "ethers";
import { useAccount } from "wagmi";

import { FundingState } from "../../utils/const";
import { useFundGoal } from "../../hooks/useFundGoal";
import { useUserInfo } from "../../hooks/useUserInfo";

import { CrowdFundingDeposit } from "./deposit";
import { CrowdFundingWithdraw } from "./withdraw";

export const CrowdFunding = () => {
  const { fundGoal, totalDeposit } = useFundGoal();
  const { userBalance, userDeposit } = useUserInfo();
  const [fundingState, setFundingState] = useState<FundingState>(
    FundingState.NOT_INITIALIZED
  );

  const { address } = useAccount();

  useEffect(() => {
    const currentTime = BigNumber.from(Math.floor(Date.now() / 1000));
    if (BigNumber.from(fundGoal.deadline).gt(0)) {
      // this means funding started
      if (BigNumber.from(fundGoal.deadline).lt(currentTime)) {
        // deadline passed
        if (BigNumber.from(totalDeposit).gte(fundGoal.goalAmount)) {
          // fully funded
          setFundingState(FundingState.FULLY_FUNDED);
        } else {
          setFundingState(FundingState.DEADLINE_PASSED);
        }
      } else {
        if (BigNumber.from(totalDeposit).gte(fundGoal.goalAmount)) {
          // fully funded
          setFundingState(FundingState.FULLY_FUNDED);
        } else {
          setFundingState(FundingState.IN_PROGRESS);
        }
      }
    } else if (BigNumber.from(fundGoal.deadline).eq(0)) {
      setFundingState(FundingState.NOT_STARTED);
    }
  }, [fundGoal]);

  const formatTime = (timeValue: BigNumber): string => {
    const selDate = new Date(Number(BigNumber.from(timeValue).mul(1e3)));
    return selDate.toLocaleTimeString() + ", " + selDate.toDateString();
  };

  return (
    <>
      <span className="pt-2 text-red-500">
        {fundingState == FundingState.NOT_INITIALIZED
          ? "Loading..."
          : fundingState == FundingState.NOT_STARTED
          ? "Funding Not Started"
          : fundingState == FundingState.FULLY_FUNDED
          ? "Fully funded, deposit/withdraw not available"
          : fundingState == FundingState.DEADLINE_PASSED
          ? "Funding Goal not met, please withdraw your funds"
          : "Funding is in progress"}
      </span>
      {[FundingState.NOT_INITIALIZED, FundingState.NOT_STARTED].indexOf(
        fundingState
      ) < 0 && (
        <>
          <p className="pt-2 text-blue-500">
            Deadline: {formatTime(fundGoal.deadline)}
          </p>
          <p className="pt-2 text-blue-500">
            Goal Amount: {utils.formatEther(fundGoal.goalAmount)} ETH
          </p>

          {address && (
            <>
              <p className="pt-2 text-blue-500">
                Your deposit amount: {utils.formatEther(userDeposit)} ETH
              </p>
              <p className="pt-2 text-blue-500">
                Your balance: {userBalance ? userBalance.toFixed(3) : "0"} ETH
              </p>

              {fundingState == FundingState.IN_PROGRESS ? (
                <CrowdFundingDeposit />
              ) : fundingState == FundingState.DEADLINE_PASSED ? (
                <CrowdFundingWithdraw />
              ) : null}
            </>
          )}
        </>
      )}
    </>
  );
};
