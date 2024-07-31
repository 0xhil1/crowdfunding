import { BigNumber } from "ethers";

export interface IFundGoal {
  token: string;
  deadline: BigNumber;
  goalAmount: BigNumber;
}
