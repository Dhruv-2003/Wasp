import React from "react";
import matic from "../public/polygon-token.svg";
import eth from "../public/ethereum.svg";
import Image from "next/image";

const Clmmmanager = () => {
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
                  <p className="text-white">Token 1</p>
                </div>
                <div className="flex align-middle px-3 py-1 border border-yellow-500 rounded-xl mt-2 bg-white">
                  <Image src={eth} className="h-6 w-6 rounded-full mr-2"/>
                  <p className="text-black">WETH</p>
                </div>
              </div>
              <div className="flex flex-col justify-center items-center">
                <div>
                  <p className="text-white">Token 2</p>
                </div>
                <div className="flex align-middle px-3 py-1 border border-yellow-500 rounded-xl mt-2 bg-white">
                  <Image src={matic} className="h-6 w-6 rounded-full mr-2"/>
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
                placeholder="Amount to be paid as a pair."
                className="w-full px-3 py-1 rounded-xl text-black"
              ></input>
            </div>
            <div className="mx-3 mt-5">
              <p className="text-xl text-yellow-500">Fees</p>
            </div>
            <div className="mt-3 mx-3">
              <input
                type="text"
                placeholder="Gas fees to be paid"
                className="w-full px-3 py-1 rounded-xl text-black"
              ></input>
            </div>
            <div className="mx-3 mt-5">
              <p className="text-yellow-500 text-xl">Email-id</p>
            </div>
            <div className="mt-3 mx-3">
              <input
                type="text"
                placeholder=""
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
{/* 
        <div className="mt-5">
          <nft-card
            contractAddress="0xc36442b4a4522e871399cd717abdd847ab11fe88"
            tokenId="67813"
            network="rinkeby"
          ></nft-card>
          <script src="https://unpkg.com/embeddable-nfts/dist/nft-card.min.js"></script>
        </div> */}
      </div>
    </div>
  );
};

export default Clmmmanager;
