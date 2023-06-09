import React, { useState, useEffect } from "react";
import matic from "../public/polygon-token.svg";
import eth from "../public/ethereum.svg";
import Image from "next/image";
// import {
//   cfav1forwarder_ABI,
//   dcafProtocol_ABI,
//   dcafWallet_ABI,
//   wmatic_ABI,
//   wmaticx_ABI,
// } from "../constants/abi";
// import {
//   CFAV1Forwarder_Address,
//   WETH_Address,
//   WMATIC_Address,
//   WMATICx_Address,
//   dcafProtocol_Address,
// } from "../constants/contracts";
import { useAccount, useWalletClient, usePublicClient } from "wagmi";
import { getContract } from "wagmi/actions";
import { Framework, SuperToken } from "@superfluid-finance/sdk-core";
import { parseEther } from "viem";

const Dca = () => {
  const [flowRateUnit, setFlowRateUnit] = useState();
  const [timePeriodInput, setTimePeriodInput] = useState("");
  const [tokens, setTokens] = useState(false);
  const [selectIn, setSelectIn] = useState("Select a Token");
  const [selectInLogo, setSelectInLogo] = useState("");
  const [dropIn, setDropIn] = useState(false);
  const [selectOut, setSelectOut] = useState("Select a Token");
  const [selectOutLogo, setSelectOutLogo] = useState("");
  const [dropOut, setDropOut] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [frequency, setFrequency] = useState({
    day: 0,
    hr: 0,
    min: 0,
    sec: 0,
  });
  const [approved, setApproved] = useState(false);
  const [superTokenAdd, setSuperTokenAdd] = useState();
  const [flowRate, setFlowRate] = useState(); // converted into wei/sec
  const [totalTimePeriod, setTotalTimePeriod] = useState(); // converted into secs from start to end
  const [dcaFreq, setDcaFreq] = useState(); // converted into secs from hours and days
  const [gelatoFees, setGelatoFees] = useState();
  const { address } = useAccount();
  const publicClient = usePublicClient();
  const { data: walletClient } = useWalletClient();
  const dcafProtocolContract = getContract({
    address: dcafProtocol_Address,
    abi: dcafProtocol_ABI,
    publicClient,
    walletClient,
  });

  const dcaf_contract = {
    address: dcafProtocol_Address,
    abi: dcafProtocol_ABI,
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
        args: [WMATICx_Address, dcafProtocol_Address],
      });
      console.log("Upgrading the asset");
      const tx = await walletClient.writeContract(request);
      console.log(tx);
      sendNotify("Operator Approval sent for confirmation ...", tx);
      const transaction = await publicClient.waitForTransactionReceipt({
        hash: tx,
      });
      console.log(transaction);
      sendNotify(
        "Approval Commpleted Successfully, Now you can create stream",
        tx
      );
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
      console.log(superTokenAdd, tokenOut, flowRate, totalTime, dcaFreq);
      const { request } = await publicClient.simulateContract({
        ...dcaf_contract,
        functionName: "createDCA",
        args: [superTokenAdd, tokenOut, flowRate, totalTime, dcaFreq],
        account: address,
        value: parseEther(gelatoFees),
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
        <div className="mt-32">
          <div className="flex flex-col justify-center items-center mx-auto">
            <div className="px-10 py-3 border border-zinc-300 rounded-xl shadow-xl">
              <div className=" bg-green-200 text-green-700 px-2 py-0.5 rounded-xl">
                <p>Send stream</p>
              </div>
              <div className="flex flex-col justify-start">
                <div className="mt-6">
                  <p className="text-2xl">Flow rate</p>
                  <div className="flex mt-2 align-middle items-center">
                    <input
                      type="number"
                      placeholder="0.0"
                      onChange={(e) => handleFlowRate(e.target.value)}
                      className="focus:border-green-500 px-2 py-2 w-full text-2xl border-slate-300"
                    ></input>
                    <Select
                      variant="filled"
                      placeholder=""
                      className="px-1 mx-3"
                      onChange={(e) => setFlowRateUnit(e.target.value)}
                    >
                      <option value="sec">/seconds</option>
                      <option value="min">/minute</option>
                      <option value="hour">/hour</option>
                      <option value="days">/days</option>
                      <option value="months">/months</option>
                    </Select>
                  </div>
                  <div className="flex flex-col mt-6">
                    <p className="text-2xl">Time Period</p>
                    <input
                      className="mt-3 text-xl"
                      type="datetime-local"
                      value={timePeriodInput}
                      onChange={(e) => setTimePeriodInput(e.target.value)}
                    ></input>
                  </div>
                  <div className="flex flex-col mt-6">
                    <p className="text-2xl">DCA Frequency</p>
                    <div className="flex align-middle items-center mt-2">
                      <input
                        type="number"
                        placeholder="0 days"
                        className="w-28 px-2 text-xl"
                        // value={frequency.day}
                        onChange={(event) => {
                          setFrequency({
                            ...frequency,
                            day: event.target.value,
                          });
                        }}
                      ></input>
                      <p className="mx-2 text-xl">+</p>
                      <input
                        type="number"
                        placeholder="0 hours"
                        className="w-28 px-2 text-xl"
                        // value={frequency.hr}
                        onChange={(event) => {
                          setFrequency({
                            ...frequency,
                            hr: event.target.value,
                          });
                        }}
                      ></input>
                      <p className="mx-2 text-xl">+</p>
                      <input
                        type="number"
                        placeholder="0 minutes"
                        className="w-28 px-2 text-xl"
                        // value={frequency.min}
                        onChange={(event) => {
                          setFrequency({
                            ...frequency,
                            min: event.target.value,
                          });
                        }}
                      ></input>
                      <p className="mx-2 text-xl">+</p>
                      <input
                        type="number"
                        placeholder="0 seconds"
                        className="w-28 px-2 text-xl"
                        // value={frequency.sec}
                        onChange={(event) => {
                          setFrequency({
                            ...frequency,
                            sec: event.target.value,
                          });
                        }}
                      ></input>
                      <p className="mx-2 text-xl"></p>
                    </div>
                  </div>
                  <div className="mt-6 flex flex-col">
                    <p className="text-black text-2xl">Gelato Fees</p>
                    <input
                      type="number"
                      placeholder="0.0"
                      onChange={(e) => setGelatoFees(e.target.value)}
                      className="focus:border-green-500 px-2 py-2 w-full text-2xl border-slate-300 mt-3"
                    ></input>
                  </div>

                  <div className="flex justify-between mt-10">
                    {isLoading ? (
                      <div className="flex justify-center items-center">
                        <Spinner size={"lg"}></Spinner>
                      </div>
                    ) : (
                      <>
                        <button
                          onClick={() => approveOperator()}
                          className={`bg-blue-400 text-white px-10 py-3 rounded-xl text-lg ${
                            approved
                              ? `cursor-not-allowed`
                              : `cursor-pointer hover:bg-white hover:text-blue-500 hover:border hover:border-blue-500 duration-200`
                          }`}
                        >
                          Approve Stream
                        </button>
                        <button
                          onClick={() => createDCAOrder()}
                          className={`bg-green-500 text-white px-10 py-3 rounded-xl text-lg  ${
                            approved
                              ? `hover:bg-white hover:text-green-500 hover:border hover:border-green-500 duration-200 cursor-pointer`
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
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dca;
