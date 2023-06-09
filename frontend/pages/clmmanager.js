import React, { useState, useEffect } from "react";
import {
  WASPMASTER_ABI,
  WASPWALLET_ABI,
  WETH_ABI,
  WMATIC_ABI,
  LINK_ABI,
} from "../constants/abi";
import {
  WASPMASTER_ADDRESS,
  WETH_Address,
  WMATIC_Address,
  LINK_Address,
} from "../constants/contracts";
import { useAccount, useWalletClient, usePublicClient } from "wagmi";
import { getContract } from "wagmi/actions";
import { parseEther, encodeAbiParameters, parseAbiParameters } from "viem";
import matic from "../public/polygon-token.svg";
import eth from "../public/ethereum.svg";
import Image from "next/image";
import Clmdashboard from "../components/clmdashboard";
// import { Spinner } from "@chakra-ui/react";
// import { useToast } from "@chakra-ui/react";

const Clmmmanager = () => {
  const [clmOrderId, setClmOrderId] = useState(1);
  const [token0Address, setToken0Address] = useState(WMATIC_Address);
  const [token1Address, setToken1Address] = useState(WETH_Address);
  const [amount0, setAmount0] = useState();
  const [amount1, setAmount1] = useState();
  const [feeRate, setFeeRate] = useState();
  const [linkAmount, setLinkAmount] = useState();
  const [email, setEmail] = useState();
  const [isLoading, setIsLoading] = useState(false);
  const { address } = useAccount();
  const publicClient = usePublicClient();
  const { data: walletClient } = useWalletClient();

  const waspManager_Contract = {
    address: WASPMASTER_ADDRESS,
    abi: WASPMASTER_ABI,
  };

  // const sendNotify = (message, txId) => {
  //   toast({
  //     position: "bottom",
  //     duration: 4000,
  //     render: () => (
  //       <Box color="white" p={3} bg="blue.500">
  //         <a target="_blank" href={`https://mumbai.polygonscan.com/tx/${txId}`}>
  //           {message}
  //         </a>
  //       </Box>
  //     ),
  //   });
  // };

  const approveToken0 = async () => {
    try {
      setIsLoading(true);
      const _amount0 = parseEther(amount0);
      const { request } = await publicClient.simulateContract({
        address: WMATIC_Address,
        abi: WMATIC_ABI,
        functionName: "approve",
        account: address,
        args: [WASPMASTER_ADDRESS, _amount0],
      });
      console.log("Upgrading the asset");
      const tx = await walletClient.writeContract(request);
      console.log(tx);
      // sendNotify("Operator Approval sent for confirmation ...", tx);
      const transaction = await publicClient.waitForTransactionReceipt({
        hash: tx,
      });
      console.log(transaction);
      // sendNotify(
      //   "Approval Commpleted Successfully, Now you can create stream",
      //   tx
      // );
      setIsLoading(false);
    } catch (error) {
      setIsLoading(false);
      console.log(error);
      window.alert(error);
    }
  };

  const approveToken1 = async () => {
    try {
      setIsLoading(true);
      const _amount1 = parseEther(amount1);
      const { request } = await publicClient.simulateContract({
        address: WETH_Address,
        abi: WETH_ABI,
        functionName: "approve",
        account: address,
        args: [WASPMASTER_ADDRESS, _amount1],
      });
      console.log("Upgrading the asset");
      const tx = await walletClient.writeContract(request);
      console.log(tx);
      // sendNotify("Operator Approval sent for confirmation ...", tx);
      const transaction = await publicClient.waitForTransactionReceipt({
        hash: tx,
      });
      console.log(transaction);
      // sendNotify(
      //   "Approval Commpleted Successfully, Now you can create stream",
      //   tx
      // );
      setIsLoading(false);
    } catch (error) {
      setIsLoading(false);
      console.log(error);
      window.alert(error);
    }
  };

  const approveLink = async () => {
    try {
      setIsLoading(true);
      const amount = parseEther(linkAmount);
      const { request } = await publicClient.simulateContract({
        address: LINK_Address,
        abi: LINK_ABI,
        functionName: "approve",
        account: address,
        args: [WASPMASTER_ADDRESS, amount],
      });
      console.log("Upgrading the asset");
      const tx = await walletClient.writeContract(request);
      console.log(tx);
      // sendNotify("Operator Approval sent for confirmation ...", tx);
      const transaction = await publicClient.waitForTransactionReceipt({
        hash: tx,
      });
      console.log(transaction);
      // sendNotify(
      //   "Approval Commpleted Successfully, Now you can create stream",
      //   tx
      // );
      setIsLoading(false);
    } catch (error) {
      setIsLoading(false);
      console.log(error);
      window.alert(error);
    }
  };

  const createCLMOrder = async () => {
    try {
      setIsLoading(true);
      console.log(
        token0Address,
        token1Address,
        amount0,
        amount1,
        linkAmount,
        feeRate,
        email
      );
      if (
        !token0Address &&
        !token1Address &&
        !amount0 &&
        !amount1 &&
        !feeRate &&
        !linkAmount &&
        !email
      ) {
        console.log("INPUTS INVALID");
        return;
      }

      const _amount0 = parseEther(amount0);
      const _amount1 = parseEther(amount1);
      const _linkAmount = parseEther(linkAmount);
      const encryptedEmail = encodeAbiParameters(
        parseAbiParameters("string email"),
        [`${email}`]
      );
      console.log(_amount0, _amount1, _linkAmount, encryptedEmail);
      const { request } = await publicClient.simulateContract({
        ...waspManager_Contract,
        functionName: "createCLMOrder",
        account: address,
        args: [
          token0Address,
          token1Address,
          _amount0,
          _amount1,
          feeRate,
          _linkAmount,
          encryptedEmail,
        ],
      });
      const tx = await walletClient.writeContract(request);
      // sendNotify("createDCAOrder sent for confirmation ..", tx);
      console.log(tx);
      const transaction = await publicClient.waitForTransactionReceipt({
        hash: tx,
      });
      console.log(transaction);
      setIsLoading(false);
      setClmOrderId(2);
      // sendNotify("Order Created Successfully", tx);
    } catch (error) {
      console.log(error);
      window.alert(error);
      setIsLoading(false);
    }
  };
  return (
    <div className="w-screen">
      <div className="mt-10 flex flex-col justify-center items-center mx-3 md:mx-0">
        <div className="md:w-1/3 w-full border-4 border-yellow-500 px-4 py-3 rounded-2xl">
          <div className="flex flex-col">
            <div>
              <p className="mx-3 text-yellow-500 text-xl">Token Pair</p>
            </div>
            <div className="w-full flex justify-around mt-4">
              <div className="flex flex-col justify-center items-center">
                <div>
                  <p className="text-white text-lg">Token 1</p>
                </div>
                <div className="flex align-middle px-3 py-1 border border-yellow-500 rounded-xl mt-2 bg-white">
                  <Image src={eth} className="h-6 w-6 rounded-full mr-2" />
                  <p className="text-black">WETH</p>
                </div>
              </div>
              <div className="flex flex-col justify-center items-center">
                <div>
                  <p className="text-white text-lg">Token 2</p>
                </div>
                <div className="flex align-middle px-3 py-1 border border-yellow-500 rounded-xl mt-2 bg-white">
                  <Image src={matic} className="h-6 w-6 rounded-full mr-2" />
                  <p className="text-black">Matic</p>
                </div>
              </div>
            </div>
            <div className="mx-3 mt-5">
              <p className="text-yellow-500 text-xl">Amount 0</p>
            </div>
            <div className="mt-3 mx-3">
              <input
                onChange={(e) => setAmount0(e.target.value)}
                type="text"
                placeholder="Amount to be paid as a pair."
                className="w-full px-3 py-1 rounded-xl text-black"
              ></input>
            </div>
            <div className="mx-3 mt-5">
              <p className="text-yellow-500 text-xl">Amount 1</p>
            </div>
            <div className="mt-3 mx-3">
              <input
                onChange={(e) => setAmount1(e.target.value)}
                type="text"
                placeholder="Amount to be paid as a pair."
                className="w-full px-3 py-1 rounded-xl text-black"
              ></input>
            </div>
            <div className="mx-3 text-yellow-500 text-xl mt-5">
              <p className="text-yellow-500">Fees</p>
            </div>
            <div className="mt-3 mx-3">
              <input
                type="number"
                placeholder="Fee Rate for the Pool"
                className="w-full px-3 py-1 rounded-xl text-black"
                onChange={(e) => setFeeRate(e.target.value)}
              ></input>
            </div>
            <div className="mx-3 text-yellow-500 text-xl mt-5">
              <p className="text-yellow-500">Link amount</p>
            </div>
            <div className="mt-3 mx-3">
              <input
                type="text"
                placeholder="Amount of Link for Upkeep &nbsp; (minumum : 0.02)"
                className="w-full px-3 py-1 rounded-xl text-black"
                onChange={(e) => setLinkAmount(e.target.value)}
              ></input>
            </div>
            <div className="mx-3 text-yellow-500 text-xl mt-5">
              <p className="text-yellow-500">Email-id</p>
            </div>
            <div className="mt-3 mx-3">
              <input
                type="text"
                placeholder="to notify when link amount runs out"
                className="w-full px-3 py-1 rounded-xl text-black"
                onChange={(e) => setEmail(e.target.value)}
              ></input>
            </div>
            <div className="flex justify-center items-center mt-8 mb-2">
              <button
                onClick={() => createCLMOrder()}
                className="bg-yellow-500 px-5 py-2 border border-white rounded-2xl text-black hover:scale-105 hover:bg-black hover:border-yellow-500 hover:text-white duration-200"
              >
                {isLoading ? `creating an order ...` : `Start an Order`}
              </button>
            </div>
          </div>
        </div>
        <Clmdashboard clmOrderId={clmOrderId} />
      </div>
    </div>
  );
};

export default Clmmmanager;
