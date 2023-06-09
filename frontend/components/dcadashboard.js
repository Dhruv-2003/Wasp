import React, { useState } from "react";

const DCAdashboard = () => {

//   const [orderId, setOrderId] = useState([]);
//   const [flowRate, setFlowRate] = useState([]);
//   const [freq, setFrew] = useState([]);
//   const [endAt, setEndAt] = useState([]);
//   const [wallet, setWallet] = useState([]);
  const [dcaOrderData, setDcaOrderData] = useState();

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
                <th className="text-yellow-500 text-xl">Flow Rate</th>
                <th className="text-yellow-500 text-xl">Frequency</th>
                <th className="text-yellow-500 text-xl">Ending At</th>
                <th className="text-yellow-500 text-xl">Wallet Address</th>
              </tr>
              <tr className="flex flex-col justify-center items-center">
                {dcaOrderData.orderId.map((key,value) => {
                    return(
                        <p className="text-white text-lg mt-5">{value}</p>
                    )
                })}
              </tr>
              <tr className="flex flex-col justify-center items-center">
                {dcaOrderData.flowRate.map((key,value) => {
                    return(
                        <p className="text-white text-lg mt-5">{value}</p>
                    )
                })}
              </tr>
              <tr className="flex flex-col justify-center items-center">
                {dcaOrderData.freq.map((key,value) => {
                    return(
                        <p className="text-white text-lg mt-5">{value}</p>
                    )
                })}
              </tr>
              <tr className="flex flex-col justify-center items-center">
                {dcaOrderData.endAt.map((key,value) => {
                    return(
                        <p className="text-white text-lg mt-5">{value}</p>
                    )
                })}
              </tr>
              <tr className="flex flex-col justify-center items-center">
                {dcaOrderData.wallet.map((key,value) => {
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

export default DCAdashboard;