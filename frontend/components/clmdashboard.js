import React, { useState } from "react";

const Clmdashboard = () => {

  const [orderId, setOrderId] = useState([]);
  const [tokenPair, setTokenPair] = useState([]);
  const [amount1, setAmount1] = useState([]);
  const [amount2, setAmount2] = useState([]);
  const [wallet, setWallet] = useState([]);

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
                {orderId.map((key,value) => {
                    return(
                        <p className="text-white text-lg mt-5">{value}</p>
                    )
                })}
              </tr>
              <tr className="flex flex-col justify-center items-center">
                {tokenPair.map((key,value) => {
                    return(
                        <p className="text-white text-lg mt-5">{value}</p>
                    )
                })}
              </tr>
              <tr className="flex flex-col justify-center items-center">
                {amount1.map((key,value) => {
                    return(
                        <p className="text-white text-lg mt-5">{value}</p>
                    )
                })}
              </tr>
              <tr className="flex flex-col justify-center items-center">
                {amount2.map((key,value) => {
                    return(
                        <p className="text-white text-lg mt-5">{value}</p>
                    )
                })}
              </tr>
              <tr className="flex flex-col justify-center items-center">
                {wallet.map((key,value) => {
                    return(
                        <p className="text-white text-lg mt-5">{value}</p>
                    )
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
