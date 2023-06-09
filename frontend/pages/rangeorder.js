import React from "react";
import matic from "../public/polygon-token.svg";
import eth from "../public/ethereum.svg";
import Image from "next/image";
import { useAccount, useWalletClient, usePublicClient } from "wagmi";
import { getContract } from "wagmi/actions";
import { parseEther, encodeAbiParameters, parseAbiParameters } from "viem";
import {
    RANGEMASTER_ABI,
    WMATIC_ABI,
    WETH_ABI,
    LINK_ABI
  } from "../constants/abi";
  import {
    RANGEMASTER_ADDRESS,
    WETH_Address,
    WMATIC_Address,
    LINK_Address,
  } from "../constants/contracts";

const Rangeorder = () => {

    const RangeMaster_Contract = {
        address: RANGEMASTER_ADDRESS,
        abi: RANGEMASTER_ABI,
    };

  return (
    <div>
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
                <p className="text-yellow-500 text-xl">Amount</p>
              </div>
              <div className="mt-3 mx-3">
                <input
                  type="text"
                  placeholder="Amount to be paid"
                  className="w-full px-3 py-1 rounded-xl text-black"
                ></input>
              </div>
              <div className="mx-3 mt-5">
                <p className="text-yellow-500 text-xl">Sell At</p>
              </div>
              <div className="mt-3 mx-3">
                <input
                  type="text"
                  placeholder="Amount to be sold at"
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
                ></input>
              </div>
              <div className="flex justify-center items-center mt-8 mb-2">
                <button className="bg-yellow-500 px-5 py-2 border border-white rounded-2xl text-black hover:scale-105 hover:bg-black hover:border-yellow-500 hover:text-white duration-200">
                  Start an Order
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Rangeorder;
