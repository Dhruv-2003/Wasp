import React from "react";

const Clmmmanager = () => {
  return (
    <div className="w-screen">
      <div className="mt-20 flex flex-col justify-center items-center mx-3 md:mx-0">
        <div className="md:w-1/3 w-full border-4 border-yellow-500 px-4 py-3 rounded-2xl">
          <div className="flex flex-col">
            <div>
              <p className="mx-3">Token Pair</p>
            </div>
            <div className="w-full flex justify-around mt-4">
              <div className="flex flex-col justify-center items-center">
                <div>
                  <p>Token 1</p>
                </div>
                <div className="flex align-middle px-3 py-1 border border-white rounded-xl mt-2">
                  <p>ETH</p>
                </div>
              </div>
              <div className="flex flex-col">
                <div>
                  <p>Token 2</p>
                </div>
                <div className="flex align-middle px-3 py-1 border border-white rounded-xl mt-2">
                  <p>USDC</p>
                </div>
              </div>
            </div>
            <div className="mx-3 mt-5">
              <p>Amount</p>
            </div>
            <div className="mt-3 mx-3">
              <input type="text" placeholder="Amount to be paid as a pair." className="w-full px-3 py-1 rounded-xl text-black"></input>
            </div>
            <div className="mx-3 mt-5">
              <p>Fees</p>
            </div>
            <div className="mt-3 mx-3">
              <input type="text" placeholder="Gas fees to be paid" className="w-full px-3 py-1 rounded-xl text-black"></input>
            </div>
            <div className="mx-3 mt-5">
              <p>Email-id</p>
            </div>
            <div className="mt-3 mx-3">
              <input type="text" placeholder="" className="w-full px-3 py-1 rounded-xl text-black"></input>
            </div>
            <div className="flex justify-center items-center mt-8 mb-2">
              <button className="bg-yellow-500 px-5 py-2 border border-white rounded-2xl text-black hover:scale-105 hover:bg-black hover:border-yellow-500 hover:text-white duration-200">Start an Order</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Clmmmanager;
