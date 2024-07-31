import _ from "lodash";
import { BigNumber, constants } from "ethers";
import { useEffect, useState } from "react";

import { IFundGoal } from "../utils/types";
import { getFundGoalInfo, getDepositInfo } from "../utils/contract";

const initFundGoal: IFundGoal = {
  token: constants.AddressZero,
  deadline: BigNumber.from(-1),
  goalAmount: BigNumber.from(0),
};

export const useFundGoal = () => {
  const [fundGoal, setFundGoal] = useState<IFundGoal>(initFundGoal);
  const [totalDeposit, setTotalDeposit] = useState<BigNumber>(
    BigNumber.from(0)
  );

  useEffect(() => {
    fetchGoalInfo();
  }, []);

  const fetchGoalInfo = async () => {
    const fundInfo = await getFundGoalInfo();
    const depositInfo = await getDepositInfo();
    setFundGoal(fundInfo);
    setTotalDeposit(depositInfo);
  };

  return { fundGoal, totalDeposit };
};
