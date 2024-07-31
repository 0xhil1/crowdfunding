import React, { useState } from "react";

import { Spinner } from "../common/Spinner";
import { doDeposit } from "../../utils/contract";
import { useUserInfo } from "../../hooks/useUserInfo";
import { showNotification, NotificationType } from "../../utils/notification";

export const CrowdFundingDeposit = () => {
  const [depositAmt, setDepositAmt] = useState<string>("");

  const { userBalance, loading, setLoading } = useUserInfo();

  const depositAction = async () => {
    if (depositAmt.length == 0) {
      showNotification("Please insert amount", NotificationType.ERROR);
      return;
    }

    const depositAmount = Number(depositAmt);
    if (depositAmount >= userBalance) {
      showNotification("Insufficient balance", NotificationType.ERROR);
      return;
    }

    setLoading(true);

    await doDeposit(depositAmt);

    setLoading(false);
  };

  return (
    <div className="max-w-sm mt-5">
      {loading ? (
        <Spinner />
      ) : (
        <>
          <label className="block mb-2 text-sm font-medium text-gray-900 dark:text-white">
            Input the deposit amount:
          </label>
          <input
            type="number"
            id="number-input"
            aria-describedby="helper-text-explanation"
            className="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
            placeholder="10"
            value={depositAmt}
            onChange={(e) => setDepositAmt(e.target.value)}
          />
          <button
            className="mt-2 bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
            onClick={depositAction}
          >
            Deposit
          </button>
        </>
      )}
    </div>
  );
};
