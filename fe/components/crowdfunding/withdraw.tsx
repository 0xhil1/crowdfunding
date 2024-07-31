import React, { useEffect, useState } from "react";
import { BigNumber } from "ethers";

import { Spinner } from "../common/Spinner";
import { doWithdraw } from "../../utils/contract";
import { useUserInfo } from "../../hooks/useUserInfo";
import { showNotification, NotificationType } from "../../utils/notification";

export const CrowdFundingWithdraw = () => {
  const { userDeposit, loading, setLoading } = useUserInfo();

  const withdrawAction = async () => {
    if (BigNumber.from(userDeposit).eq(0)) {
      showNotification("No withdrawbla amount", NotificationType.ERROR);
      return;
    }

    setLoading(true);
    await doWithdraw();
    setLoading(false);
  };

  return (
    <div className="max-w-sm mt-5">
      {loading ? (
        <Spinner />
      ) : (
        <button
          className="mt-2 bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          onClick={withdrawAction}
        >
          Withdraw
        </button>
      )}
    </div>
  );
};
