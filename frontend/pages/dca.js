import React, { useState, useEffect } from "react";
import matic from "../public/polygon-token.svg";
import eth from "../public/ethereum.svg";
import Image from "next/image";
import { DCAMASTER_ABI, LINK_ABI, cfav1forwarder_ABI } from "../constants/abi";
import {
  DCAMASTER_ADDRESS,
  CFAV1Forwarder_Address,
  WMATICx_Address,
  WETH_Address,
  LINK_Address,
} from "../constants/contracts";
import { useAccount, useWalletClient, usePublicClient } from "wagmi";
import { getContract } from "wagmi/actions";
import { parseEther, encodeAbiParameters, parseAbiParameters } from "viem";
import DCAdashboard from "../components/dcadashboard";

const Dca = () => {
  const [flowRateUnit, setFlowRateUnit] = useState();
  const [timePeriodInput, setTimePeriodInput] = useState("");
  // const [tokens, setTokens] = useState(false);
  //   const [selectIn, setSelectIn] = useState("Select a Token");
  //   const [selectInLogo, setSelectInLogo] = useState("");
  //   const [dropIn, setDropIn] = useState(false);
  //   const [selectOut, setSelectOut] = useState("Select a Token");
  //   const [selectOutLogo, setSelectOutLogo] = useState("");
  //   const [dropOut, setDropOut] = useState(false);
  const [tokenIn, setTokenIn] = useState();
  const [tokenOut, setTokenOut] = useState(WETH_Address);
  const [linkAmount, setLinkAmount] = useState();
  const [email, setEmail] = useState();
  const [isLoading, setIsLoading] = useState(false);
  const [frequency, setFrequency] = useState({
    day: 0,
    hr: 0,
    min: 0,
    sec: 0,
  });
  const [approved, setApproved] = useState(false);
  const [superTokenAdd, setSuperTokenAdd] = useState(WMATICx_Address);
  const [flowRate, setFlowRate] = useState(); // converted into wei/sec
  const [totalTimePeriod, setTotalTimePeriod] = useState(); // converted into secs from start to end
  const [dcaFreq, setDcaFreq] = useState(); // converted into secs from hours and days
  const [gelatoFees, setGelatoFees] = useState();
  const { address } = useAccount();
  const publicClient = usePublicClient();
  const { data: walletClient } = useWalletClient();

  const dcaf_contract = {
    address: DCAMASTER_ADDRESS,
    abi: DCAMASTER_ABI,
  };

  const handleFlowRate = (_flowRate) => {
    // console.log(_flowRate);
    if (!_flowRate) return;
    if (flowRateUnit == "sec") {
      setFlowRate(parseEther(`${_flowRate}`));
    } else if (flowRateUnit == "min") {
      setFlowRate(parseEther(`${_flowRate / 60}`));
    } else if (flowRateUnit == "hour") {
      setFlowRate(parseEther(`${_flowRate / (60 * 60)}`));
    } else if (flowRateUnit == "days") {
      setFlowRate(parseEther(`${_flowRate / (60 * 60 * 24)}`));
    } else if (flowRateUnit == "months") {
      setFlowRate(parseEther(`${_flowRate / (60 * 60 * 24 * 30)}`));
    } else {
      console.log("Invalid Unit");
    }
  };

  const getFrequency = () => {
    const freq =
      frequency.day * 86400 +
      frequency.hr * 3600 +
      frequency.min * 60 +
      frequency.sec * 1;
    return freq;
  };

  const toUnixTime = (year, month, day, hr, min, sec) => {
    const date = new Date(Date.UTC(year, month - 1, day, hr, min, sec));
    return Math.floor(date.getTime() / 1000);
  };
  const getTotalTime = () => {
    const datetime = new Date(timePeriodInput);
    const year = datetime.getFullYear();
    const month = datetime.getMonth() + 1;
    const day = datetime.getDate();
    const hr = datetime.getHours();
    const min = datetime.getMinutes();
    const sec = datetime.getSeconds();
    const endTime = toUnixTime(year, month, day, hr, min, sec);
    console.log(endTime);
    const currentTime = Math.floor(new Date() / 1000);
    console.log(currentTime);
    const totalTime = endTime - currentTime;
    setTotalTimePeriod(totalTime);
    console.log(totalTime);
    return totalTime;
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
        args: [DCAMASTER_ABI, amount],
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

  const approveOperator = async () => {
    try {
      if (!flowRate) {
        console.log("Enter Flow rate to be allowed");
        return;
      }

      setIsLoading(true);
      const { request } = await publicClient.simulateContract({
        address: CFAV1Forwarder_Address,
        abi: cfav1forwarder_ABI,
        functionName: "grantPermissions",
        account: address,
        args: [WMATICx_Address, DCAMASTER_ADDRESS],
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
      setApproved(true);
      setIsLoading(false);
    } catch (error) {
      setIsLoading(false);
      console.log(error);
      window.alert(error);
    }
  };

  const createDCAOrder = async () => {
    try {
      const dcaFreq = await getFrequency();
      const totalTime = await getTotalTime();
      if (!flowRate && !totalTime && !dcaFreq && !gelatoFees) {
        console.log("Check your inputs");
        window.alert("Check inputs");
        return;
      }
      setIsLoading(true);
      const _linkAmount = parseEther(linkAmount);
      const encryptedEmail = encodeAbiParameters(
        parseAbiParameters("string email"),
        [`${email}`]
      );
      console.log(
        superTokenAdd,
        tokenOut,
        flowRate,
        totalTime,
        dcaFreq,
        encryptedEmail
      );
      const { request } = await publicClient.simulateContract({
        ...dcaf_contract,
        functionName: "createDCA",
        args: [
          superTokenAdd,
          tokenOut,
          flowRate,
          totalTime,
          dcaFreq,
          _linkAmount,
          encryptedEmail,
        ],
        account: address,
      });
      const tx = await walletClient.writeContract(request);
      sendNotify("createDCAOrder sent for confirmation ..", tx);
      console.log(tx);
      const transaction = await publicClient.waitForTransactionReceipt({
        hash: tx,
      });
      console.log(transaction);
      setIsLoading(false);
      sendNotify("Order Created Successfully", tx);
    } catch (error) {
      console.log(error);
      window.alert(error);
      setIsLoading(false);
    }
  };

  return (
    <div className="w-full">
      <div className="flex justify-center items-center mx-auto ">
        <div className="mt-10">
          <div className="flex flex-col justify-center items-center mx-auto">
            <div className="px-10 py-3 border-2 border-yellow-300 rounded-xl shadow-xl">
              <div className="flex flex-col justify-start">
                <div>
                  <p className="text-xl text-yellow-500">Token Pair</p>
                  <div className="w-full flex justify-around mt-4">
                    <div className="flex flex-col justify-center items-center">
                      <div>
                        <p className="text-white text-lg">Token In</p>
                      </div>
                      <div className="flex align-middle px-3 py-1 border border-yellow-500 rounded-xl mt-2 bg-white">
                        <Image
                          src={eth}
                          className="h-6 w-6 rounded-full mr-2"
                        />
                        <p className="text-black">WETH</p>
                      </div>
                    </div>
                    <div className="flex flex-col justify-center items-center">
                      <div>
                        <p className="text-white text-lg">Token Out</p>
                      </div>
                      <div className="flex align-middle px-3 py-1 border border-yellow-500 rounded-xl mt-2 bg-white">
                        <Image
                          src={matic}
                          className="h-6 w-6 rounded-full mr-2"
                        />
                        <p className="text-black">Wrapped Matic</p>
                      </div>
                    </div>
                  </div>
                </div>
                <div className="mt-6">
                  <p className="text-xl text-yellow-500">Flow rate</p>
                  <div className="flex mt-2 align-middle items-center">
                    <input
                      type="number"
                      placeholder="0.0"
                      onChange={(e) => handleFlowRate(e.target.value)}
                      className="focus:border-green-500 px-2 py-1 w-full text-xl border-slate-300 rounded-xl"
                    ></input>
                    <select
                      placeholder=""
                      className="px-1 mx-3 py-2 bg-yellow-500 text-black rounded-xl"
                      onChange={(e) => setFlowRateUnit(e.target.value)}
                    >
                      <option value="sec">/seconds</option>
                      <option value="min">/minute</option>
                      <option value="hour">/hour</option>
                      <option value="days">/days</option>
                      <option value="months">/months</option>
                    </select>
                  </div>
                  <div className="flex flex-col mt-6">
                    <p className="text-xl text-yellow-500">Time Period</p>
                    <input
                      className="mt-3 text-xl px-2 py-1 rounded-xl"
                      type="datetime-local"
                      value={timePeriodInput}
                      onChange={(e) => setTimePeriodInput(e.target.value)}
                    ></input>
                  </div>
                  <div className="flex flex-col mt-6">
                    <p className="text-xl text-yellow-500">DCA Frequency</p>
                    <div className="flex align-middle items-center mt-4">
                      <input
                        type="number"
                        placeholder="0 days"
                        className="w-28 px-2 text-xl rounded-xl py-1"
                        // value={frequency.day}
                        onChange={(event) => {
                          setFrequency({
                            ...frequency,
                            day: event.target.value,
                          });
                        }}
                      ></input>
                      <p className="mx-2 text-xl text-yellow-500">+</p>
                      <input
                        type="number"
                        placeholder="0 hours"
                        className="w-28 px-2 text-xl rounded-xl py-1"
                        // value={frequency.hr}
                        onChange={(event) => {
                          setFrequency({
                            ...frequency,
                            hr: event.target.value,
                          });
                        }}
                      ></input>
                      <p className="mx-2 text-xl text-yellow-500">+</p>
                      <input
                        type="number"
                        placeholder="0 minutes"
                        className="w-32 px-2 text-xl rounded-xl py-1"
                        // value={frequency.min}
                        onChange={(event) => {
                          setFrequency({
                            ...frequency,
                            min: event.target.value,
                          });
                        }}
                      ></input>
                      <p className="mx-2 text-xl text-yellow-500">+</p>
                      <input
                        type="number"
                        placeholder="0 seconds"
                        className="w-28 px-2 text-xl rounded-xl py-1"
                        // value={frequency.sec}
                        onChange={(event) => {
                          setFrequency({
                            ...frequency,
                            sec: event.target.value,
                          });
                        }}
                      ></input>
                      <p className="mx-2 text-xl text-yellow-500"></p>
                    </div>
                  </div>
                  <div className="mt-6 flex flex-col">
                    <p className="text-yellow-500 text-xl">Fees in Link</p>
                    <input
                      type="number"
                      placeholder="0.0"
                      onChange={(e) => setLinkAmount(e.target.value)}
                      className="focus:border-green-500 px-2 py-1 rounded-xl w-full text-xl border-slate-300 mt-3"
                    ></input>
                  </div>

                  <div className="flex justify-between mt-10">
                    {isLoading ? (
                      <div className="flex justify-center items-center">
                        {/* <Spinner size={"lg"}></Spinner> */}
                      </div>
                    ) : (
                      <>
                        <button
                          onClick={() => approveOperator()}
                          className={`bg-yellow-500 text-black px-6 py-2 rounded-xl text-xl mb-5 ${
                            approved
                              ? `cursor-not-allowed`
                              : `cursor-pointer hover:bg-black hover:text-yellow-500 hover:border hover:border-yellow-500 duration-200`
                          }`}
                        >
                          Approve Stream
                        </button>
                        <button
                          onClick={() => createDCAOrder()}
                          className={`bg-black text-yellow-500 border border-yellow-500 px-6 py-2 rounded-xl text-xl mb-5 ${
                            approved
                              ? `hover:bg-yellow-500 hover:text-black hover:border hover:border-yellow-500 duration-200 cursor-pointer`
                              : `cursor-not-allowed`
                          }`}
                        >
                          Start stream
                        </button>
                      </>
                    )}
                  </div>
                </div>
              </div>
            </div>
            <DCAdashboard />
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dca;
