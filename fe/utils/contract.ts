import {
  readContract,
  writeContract,
  createConfig,
  http,
  getBalance,
  waitForTransactionReceipt,
} from "@wagmi/core";
import { sepolia } from "@wagmi/core/chains";
import { decodeError } from "ethers-decode-error";
import { BigNumber, utils } from "ethers";
import { Contracts } from "./const";
import { IFundGoal } from "./types";
import { showNotification, NotificationType } from "./notification";

import abi from "./abi/crowdfund.json";

const config = createConfig({
  chains: [sepolia],
  transports: {
    [sepolia.id]: http(),
  },
});

export const getFundGoalInfo = async (): Promise<IFundGoal> => {
  const goalInfo = await readContract(config, {
    abi,
    address: Contracts.crowdfund as `0x${string}`,
    functionName: "getFundGoal",
    chainId: sepolia.id,
  });

  return goalInfo as IFundGoal;
};

export const getDepositInfo = async (): Promise<BigNumber> => {
  const depositInfo = await readContract(config, {
    abi,
    address: Contracts.crowdfund as `0x${string}`,
    functionName: "totalDeposits",
    chainId: sepolia.id,
  });

  return BigNumber.from(depositInfo);
};

export const doDeposit = async (amount: string): Promise<string> => {
  try {
    const depositAmt = utils.parseEther(amount).toString();
    const txHash = await writeContract(config, {
      address: Contracts.crowdfund as `0x${string}`,
      abi: abi,
      functionName: "deposit",
      args: [depositAmt],
      chainId: sepolia.id,
      value: BigInt(depositAmt),
    });

    await waitForTransactionReceipt(config, {
      hash: txHash,
    });

    return txHash;
  } catch (err) {
    const decordedErr = decodeError(err);
    showNotification(decordedErr.error, NotificationType.ERROR);
    return decordedErr.error || "";
  }
};

export const doWithdraw = async (): Promise<string> => {
  try {
    const txHash = await writeContract(config, {
      address: Contracts.crowdfund as `0x${string}`,
      abi: abi,
      functionName: "withdraw",
      chainId: sepolia.id,
    });

    await waitForTransactionReceipt(config, {
      hash: txHash,
    });

    return txHash;
  } catch (err) {
    const decordedErr = decodeError(err);
    showNotification(decordedErr.error, NotificationType.ERROR);
    return decordedErr.error || "";
  }
};

export const getUserDeposit = async (userAddr: string): Promise<BigNumber> => {
  const userDeposit = await readContract(config, {
    abi,
    address: Contracts.crowdfund as `0x${string}`,
    functionName: "userDeposits",
    args: [userAddr],
    chainId: sepolia.id,
  });

  return userDeposit as BigNumber;
};

export const getUserBalance = async (userAddr: string): Promise<number> => {
  const balance = await getBalance(config, {
    address: userAddr as `0x${string}`,
    chainId: sepolia.id,
  });

  return Number(utils.formatEther(balance.value));
};
