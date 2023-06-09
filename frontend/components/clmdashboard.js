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
  const [orderId, setOrderId] = useState([]);
  const [tokenPair, setTokenPair] = useState([]);
  const [amount1, setAmount1] = useState([]);
  const [amount2, setAmount2] = useState([]);
  const [wallet, setWallet] = useState([]);
  const { address } = useAccount();
  const publicClient = usePublicClient();
  const { data: walletClient } = useWalletClient();

  const waspManager_Contract = {
    address: WASPMASTER_ADDRESS,
    abi: WASPMASTER_ABI,
  };

  useEffect(() => {
    if (props.clmOrderId != 0) {
      getOrderData(props.clmOrderId);
    }
  }, [props.clmOrderId]);

  const getOrderData = async (clmOrderId) => {
    try {
      const data = await publicClient.readContract({
        ...waspManager_Contract,
        functionName: "clmOrders",
        args: [clmOrderId],
      });
      setTokenPair(["WMATIC / WETH"]);
      setWallet([data[9]]);
      setAmount1([formatEther(data[3])]);
      setAmount2([formatEther(data[4])]);
      setOrderId([data[6]]);
      getPositionData(data[9]);
      console.log(data);
    } catch (error) {
      console.log(error);
    }
  };
  // const getPositionData = async (walletAddress) => {
  //   try {
  //     const data = await publicClient.readContract({
  //       address: walletAddress,
  //       abi: WASPMASTER_ABI,
  //       functionName: "_position",
  //     });
  //     console.log(data);
  //   } catch (error) {
  //     console.log(error);
  //   }
  // };

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
                <th className="text-yellow-500 text-xl">Token Pair</th>
                <th className="text-yellow-500 text-xl">Amount 1</th>
                <th className="text-yellow-500 text-xl">Amount 2</th>
                <th className="text-yellow-500 text-xl">Wallet Address</th>
              </tr>
              <tr className="flex flex-col justify-center items-center">
                {orderId.map((value, key) => {
                  return <p className="text-white text-lg mt-5">{value}</p>;
                })}
              </tr>
              <tr className="flex flex-col justify-center items-center">
                {tokenPair.map((value, key) => {
                  return <p className="text-white text-lg mt-5">{value}</p>;
                })}
              </tr>
              <tr className="flex flex-col justify-center items-center">
                {amount1.map((value, key) => {
                  return <p className="text-white text-lg mt-5">{value}</p>;
                })}
              </tr>
              <tr className="flex flex-col justify-center items-center">
                {amount2.map((value, key) => {
                  return <p className="text-white text-lg mt-5">{value}</p>;
                })}
              </tr>
              <tr className="flex flex-col justify-center items-center">
                {wallet.map((value, key) => {
                  return <p className="text-white text-lg mt-5">{value}</p>;
                })}
              </tr>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Clmdashboard;
