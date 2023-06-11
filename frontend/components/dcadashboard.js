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
    getAllOrders();
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

  const getAllOrders = async () => {
    try {
      const data = await publicClient.readContract({
        ...dcaManager_Contract,
        functionName: "totaldcafOrders",
      });
      // console.log(data);
      if (!data) return;
      const totalOrders = Number(data);
      // console.log(totalOrders);
      const promise = [];
      for (let id = 1; id <= totalOrders; id++) {
        const data = getOrderData(id);
        promise.push(data);
      }

      const _orderData = await Promise.all(promise);
      console.log(_orderData);
      setDcaOrderData(_orderData);
    } catch (error) {
      console.log(error);
    }
  };

  const getOrderData = async (dcaOrderId) => {
    try {
      const data = await publicClient.readContract({
        ...dcaManager_Contract,
        functionName: "dcafOrders",
        args: [dcaOrderId],
      });
      // setOrderId([]);
      // setFlowRate([formatEther(data[5])]);
      // setFreq([data[7].toString()]);
      // setEndAt([handleTimePeriod(parseInt(data[6]), parseInt(data[9]))]);
      // setWallet([data[1]]);
      // setTask1Id([data[11]]);
      // setTask2Id([data[12]]);
      // setDcaOrderData(true);

      const order = {
        orderId: dcaOrderId,
        flowRate: formatEther(data[5]),
        freq: data[7].toString(),
        endAt: handleTimePeriod(parseInt(data[6]), parseInt(data[9])),
        wallet: data[1],
        task1Id: data[11],
        task2Id: data[12],
      };
      // task1Id https://automation.chain.link/mumbai/data[11]
      // task2Id https://automation.chain.link/mumbai/data[12]
      // flowRate https://app.superfluid.finance/stream/polygon-mumbai/${data[0]}-${data.[1]}-${WMATICx_Address}-0.0
      // console.log(order);
      return order;
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
            <div className="w-full flex flex-col justify-evenly">
              <div className="w-full flex justify-evenly">
                <p className="text-yellow-500 text-xl">Order Id</p>
                <p className="text-yellow-500 text-xl">Flow Rate</p>
                <p className="text-yellow-500 text-xl">Frequency</p>
                <p className="text-yellow-500 text-xl">Ending At</p>
                <p className="text-yellow-500 text-xl">Wallet Address</p>
                <p className="text-yellow-500 text-xl">Task 1 Id</p>
                <p className="text-yellow-500 text-xl">Task 2 Id</p>
              </div>
              {dcaOrderData &&
                dcaOrderData.map((dcaOrder, key) => {
                  <div className="flex justify-evenly w-full">
                    <div className="flex justify-center">
                      <p className="text-white text-lg mt-5">
                        {dcaOrder.orderId}
                      </p>
                    </div>
                    <div className="flex justify-center">
                      <p className="text-white text-lg mt-5">
                        {dcaOrder.flowRate.slice(0, -9)}
                      </p>
                    </div>
                    <div className="flex justify-center">
                      <p className="text-white text-lg mt-5">{dcaOrder.freq}</p>
                    </div>
                    <div className="flex justify-center">
                      <p className="text-white text-lg mt-5">
                        {dcaOrder.endAt}
                      </p>
                    </div>
                    <div className="flex justify-center">
                      <p className="text-white text-lg mt-5">
                        {dcaOrder.wallet.slice(0, 9)}...
                      </p>
                    </div>
                    <div className="flex justify-center">
                      <a
                        className="text-white text-lg mt-5"
                        target="_blank"
                        href={`https://automation.chain.link/mumbai/${dcaOrder.task1Id}`}
                      >
                        Task 1 ID
                      </a>
                    </div>
                    <div className="flex justify-center">
                      <a
                        className="text-white text-lg mt-5"
                        target="_blank"
                        href={`https://automation.chain.link/mumbai/${dcaOrder.task2id}`}
                      >
                        Task 2 ID
                      </a>
                    </div>
                  </div>;
                })}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DCAdashboard;
