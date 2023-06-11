import React, { useState, useEffect } from "react";
import { useAccount, useWalletClient, usePublicClient } from "wagmi";
import { WASPMASTER_ABI, WASPWALLET_ABI } from "../constants/abi";
import { WASPMASTER_ADDRESS } from "../constants/contracts";
import {
  parseEther,
  encodeAbiParameters,
  parseAbiParameters,
  formatEther,
} from "viem";
const Clmdashboard = (props) => {
  const [orderData, setOrderData] = useState();
  const [orderId, setOrderId] = useState([]);
  const [tokenPair, setTokenPair] = useState([]);
  const [amount1, setAmount1] = useState([]);
  const [amount2, setAmount2] = useState([]);
  const [wallet, setWallet] = useState([]);
  const [taskId, setTaskId] = useState([]);
  const { address } = useAccount();
  const publicClient = usePublicClient();
  const { data: walletClient } = useWalletClient();

  const waspManager_Contract = {
    address: WASPMASTER_ADDRESS,
    abi: WASPMASTER_ABI,
  };

  useEffect(() => {
    getAllOrders();
  }, [props.clmOrderId]);

  const getAllOrders = async () => {
    try {
      const data = await publicClient.readContract({
        ...waspManager_Contract,
        functionName: "totalCLMOrders",
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
      setOrderData(_orderData);
    } catch (error) {
      console.log(error);
    }
  };

  const getOrderData = async (clmOrderId) => {
    try {
      const data = await publicClient.readContract({
        ...waspManager_Contract,
        functionName: "clmOrders",
        args: [clmOrderId],
      });
      // setTokenPair([...tokenPair, "WMATIC / WETH"]);
      // setWallet([...wallet, data[9]]);
      // setAmount1([...amount1, formatEther(data[3])]);
      // setAmount2([...amount2, formatEther(data[4])]);
      // setOrderId([...orderId, data[6]]);
      // setTaskId([...taskId, data[7]]);
      if (data[0] != address) return;
      const order = {
        tokenPair: "WMATIC/WETH",
        wallet: data[9],
        amount1: formatEther(data[3]),
        amount2: formatEther(data[4]),
        orderId: data[6],
        taskId: data[7],
      };
      //   getPositionData(data[9]);
      //   opensea : https://testnets.opensea.io/assets/mumbai/0xc36442b4a4522e871399cd717abdd847ab11fe88/data[6]
      //   taskId : https://automation.chain.link/mumbai/data[7]
      console.log(order);
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
            {/* <table className="w-full"> */}
            <div className="w-full flex justify-evenly">
              <p className="text-yellow-500 text-xl">Order Id</p>
              <p className="text-yellow-500 text-xl">Token Pair</p>
              <p className="text-yellow-500 text-xl">Amount 1</p>
              <p className="text-yellow-500 text-xl">Amount 2</p>
              <p className="text-yellow-500 text-xl">Wallet Address</p>
              <p className="text-yellow-500 text-xl">Opensea NFT</p>
              <p className="text-yellow-500 text-xl">Task ID</p>
            </div>
            <div className="flex justify-evenly w-full">
              {orderData &&
                orderData.map((order, key) => {
                  <>
                    <div className="flex justify-center">
                      <p className="text-white text-lg mt-5">{order.orderId}</p>
                    </div>
                    <div className="flex justify-center">
                      <td>
                        <p className="text-white text-lg mt-5">
                          {order.tokenPair}
                        </p>
                      </td>
                    </div>
                    <div className="flex justify-center">
                      <td>
                        <p className="text-white text-lg mt-5">
                          {order.amount1}
                        </p>
                      </td>
                    </div>
                    <div className="flex justify-center">
                      <td>
                        <p className="text-white text-lg mt-5">
                          {order.amount2}
                        </p>
                      </td>
                    </div>
                    <div className="flex justify-center">
                      <p className="text-white text-lg mt-5">
                        {order.wallet.slice(0, 5)}...
                      </p>
                    </div>
                    <div className="flex justify-center align-middle">
                      <a
                        className="text-white text-lg mt-5"
                        target="_blank"
                        href={`https://testnets.opensea.io/assets/mumbai/0xc36442b4a4522e871399cd717abdd847ab11fe88/${order.orderId}`}
                      >
                        NFT Link
                      </a>
                    </div>
                    <div className="flex justify-center align-middle">
                      <a
                        className="text-white text-lg mt-5"
                        target="_blank"
                        href={` https://automation.chain.link/mumbai/${order.taskId}`}
                      >
                        Task ID
                      </a>
                    </div>
                  </>;
                })}
              {/* <div className="flex justify-center">
                {orderId.map((value, key) => {
                  return <p className="text-white text-lg mt-5">{value}</p>;
                })}
              </div>
              <div className="flex justify-center">
                {tokenPair.map((value, key) => {
                  return (
                    <td>
                      <p className="text-white text-lg mt-5">{value}</p>
                    </td>
                  );
                })}
              </div>
              <div className="flex justify-center">
                {amount1.map((value, key) => {
                  return (
                    <td>
                      <p className="text-white text-lg mt-5">{value}</p>
                    </td>
                  );
                })}
              </div>
              <div className="flex justify-center">
                {amount2.map((value, key) => {
                  return <p className="text-white text-lg mt-5">{value}</p>;
                })}
              </div>
              <div className="flex justify-center">
                {wallet.map((value, key) => {
                  return (
                    <p className="text-white text-lg mt-5">
                      {value.slice(0, 9)}...
                    </p>
                  );
                })}
              </div> */}
              {/* <div className="flex justify-center align-middle">
                <a
                  className="text-white text-lg mt-5"
                  target="_blank"
                  href={`https://testnets.opensea.io/assets/mumbai/0xc36442b4a4522e871399cd717abdd847ab11fe88/${orderId}`}
                >
                  NFT Link
                </a>
              </div>
              <div className="flex justify-center align-middle">
                <a
                  className="text-white text-lg mt-5"
                  target="_blank"
                  href={` https://automation.chain.link/mumbai/${taskId}`}
                >
                  Task ID
                </a>
              </div> */}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Clmdashboard;
