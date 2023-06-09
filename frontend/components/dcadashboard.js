import React, { useState, useEffect } from "react";
import { useAccount, useWalletClient, usePublicClient } from "wagmi";
import { DCAMASTER_ABI } from "../constants/abi";
import { DCAMASTER_ADDRESS, WMATICx_Address } from "../constants/contracts";
import {
  parseEther,
  encodeAbiParameters,
  parseAbiParameters,
  formatEther,
} from "viem";

const DCAdashboard = (props) => {
  const [orderId, setOrderId] = useState([]);
  const [flowRate, setFlowRate] = useState([]);
  const [freq, setFreq] = useState([]);
  const [endAt, setEndAt] = useState([]);
  const [wallet, setWallet] = useState([]);
  const [dcaOrderData, setDcaOrderData] = useState();

  const { address } = useAccount();
  const publicClient = usePublicClient();
  const { data: walletClient } = useWalletClient();

  const dcaManager_Contract = {
    address: DCAMASTER_ADDRESS,
    abi: DCAMASTER_ABI,
  };

  useEffect(() => {
    if (props.dcaOrderId != 0) {
      getOrderData(props.dcaOrderId);
    }
  }, [props.dcaOrderId]);

  const handleTimePeriod = (timePeriod, creationTime) => {
    // const currentTime = Math.floor(new Date() / 1000);
    // console.log(currentTime);
    const totalTime = creationTime + timePeriod;
    const endTime = timeConverter(totalTime);
    return endTime;
  };

  function timeConverter(UNIX_timestamp) {
    var a = new Date(UNIX_timestamp * 1000);
    var months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    var year = a.getFullYear();
    var month = months[a.getMonth()];
    var date = a.getDate();
    var hour = a.getHours();
    var min = a.getMinutes();
    var sec = a.getSeconds();
    var time =
      date + " " + month + " " + year + " " + hour + ":" + min + ":" + sec;
    return time;
  }

  const getOrderData = async (dcaOrderId) => {
    try {
      const data = await publicClient.readContract({
        ...dcaManager_Contract,
        functionName: "dcafOrders",
        args: [dcaOrderId],
      });
      setOrderId([]);
      setFlowRate([formatEther(data[5])]);
      setFreq([data[7].toString()]);
      setEndAt(handleTimePeriod(parseInt(data[6]), parseInt(data[9])));
      setWallet(data[1]);
      // task1Id https://automation.chain.link/mumbai/data[11]
      // task2Id https://automation.chain.link/mumbai/data[12]
      // flowRate https://app.superfluid.finance/stream/polygon-mumbai/${data[0]}-${data.[1]}-${WMATICx_Address}-0.0
      console.log(data);
    } catch (error) {
      console.log(error);
    }
  };

  return (
    <div className="w-screen">
      <div className="mt-20 mb-20">
        <div className="flex flex-col justify-center items-center">
          <div>
            <p className="text-yellow-500 text-2xl">Dashboard</p>
          </div>
          <div className="mt-10 w-1/2 border border-white px-3 py-2 rounded-xl">
            <table className="w-full">
              <tr className="w-full">
                <th className="text-yellow-500 text-xl">Order Id</th>
                <th className="text-yellow-500 text-xl">Flow Rate</th>
                <th className="text-yellow-500 text-xl">Frequency</th>
                <th className="text-yellow-500 text-xl">Ending At</th>
                <th className="text-yellow-500 text-xl">Wallet Address</th>
              </tr>
              {dcaOrderData && (
                <>
                  {" "}
                  <tr className="flex flex-col justify-center items-center">
                    {dcaOrderData.orderId.map((key, value) => {
                      return <p className="text-white text-lg mt-5">{value}</p>;
                    })}
                  </tr>
                  <tr className="flex flex-col justify-center items-center">
                    {dcaOrderData.flowRate.map((key, value) => {
                      return <p className="text-white text-lg mt-5">{value}</p>;
                    })}
                  </tr>
                  <tr className="flex flex-col justify-center items-center">
                    {dcaOrderData.freq.map((key, value) => {
                      return <p className="text-white text-lg mt-5">{value}</p>;
                    })}
                  </tr>
                  <tr className="flex flex-col justify-center items-center">
                    {dcaOrderData.endAt.map((key, value) => {
                      return <p className="text-white text-lg mt-5">{value}</p>;
                    })}
                  </tr>
                  <tr className="flex flex-col justify-center items-center">
                    {dcaOrderData.wallet.map((key, value) => {
                      return <p className="text-white text-lg mt-5">{value}</p>;
                    })}
                  </tr>
                </>
              )}
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DCAdashboard;
