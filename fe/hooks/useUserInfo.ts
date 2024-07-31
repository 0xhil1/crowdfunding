import { BigNumber, constants } from "ethers";
import { useEffect, useState } from "react";
import { useAccount } from "wagmi";

import { getUserBalance, getUserDeposit } from "../utils/contract";

export const useUserInfo = () => {
  const [loading, setLoading] = useState<boolean>(false);
  const [userBalance, setUserBalance] = useState<number>(0);
  const [userDeposit, setUserDeposit] = useState<BigNumber>(BigNumber.from(0));

  const { address } = useAccount();

  useEffect(() => {
    if (address && address.length > 0) {
      fetchUserInfo(address);
    } else {
      setUserBalance(0);
      setUserDeposit(BigNumber.from(0));
    }
  }, [address, loading]);

  const fetchUserInfo = async (address: string) => {
    const userBalance = await getUserBalance(address);
    const userDeposit = await getUserDeposit(address);
    setUserBalance(userBalance);
    setUserDeposit(userDeposit);
  };

  return { userBalance, userDeposit, loading, setLoading };
};
