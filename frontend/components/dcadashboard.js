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
  const [task1id, setTask1Id] = useState([]);
  const [task2id, setTask2Id] = useState([]);

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
      setTask1Id(data[11])
      setTask2Id(data[12])
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
          <div className="mt-10 w-9/12 border border-white px-3 py-2 rounded-xl">
            <div className="w-full flex justify-evenly">
              <div className="w-full flex justify-evenly">
                <p className="text-yellow-500 text-xl">Order Id</p>
                <p className="text-yellow-500 text-xl">Flow Rate</p>
                <p className="text-yellow-500 text-xl">Frequency</p>
                <p className="text-yellow-500 text-xl">Ending At</p>
                <p className="text-yellow-500 text-xl">Wallet Address</p>
                <p className="text-yellow-500 text-xl">Task 1 Id</p>
                <p className="text-yellow-500 text-xl">Task 2 Id</p>
              </div>
              {dcaOrderData && (
                <div className="flex justify-evenly w-full">
                  <div className="flex justify-center">
                    {dcaOrderData.orderId.map((key, value) => {
                      return <p className="text-white text-lg mt-5">{value}</p>;
                    })}
                  </div>
                  <div className="flex justify-center">
                    {dcaOrderData.flowRate.map((key, value) => {
                      return <p className="text-white text-lg mt-5">{value}</p>;
                    })}
                  </div>
                  <div className="flex justify-center">
                    {dcaOrderData.freq.map((key, value) => {
                      return <p className="text-white text-lg mt-5">{value}</p>;
                    })}
                  </div>
                  <div className="flex justify-center">
                    {dcaOrderData.endAt.map((key, value) => {
                      return <p className="text-white text-lg mt-5">{value}</p>;
                    })}
                  </div>
                  <div className="flex justify-center">
                    {dcaOrderData.wallet.map((key, value) => {
                      return <p className="text-white text-lg mt-5">{value}</p>;
                    })}
                  </div>
                  <div className="flex justify-center">
                    {dcaOrderData.wallet.map((key, value) => {
                      return <p className="text-white text-lg mt-5">{value}</p>;
                    })}
                  </div>
                  <div className="flex justify-center">
                  <a className="text-white text-lg mt-5" target="_blank" href={`https://automation.chain.link/mumbai/${task1id}`}>Task 1 ID</a>
                  </div>
                  <div className="flex justify-center">
                  <a className="text-white text-lg mt-5" target="_blank" href={`https://automation.chain.link/mumbai/${task2id}`}>Task 2 ID</a>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DCAdashboard;
