import React from "react";
import { useRouter } from "next/router";

const Homepage = () => {
  const router = useRouter();
  return (
    <div>
      <div className="w-screen mt-10">
        <div className="w-11/12 mx-auto">
          <div className="flex md:flex-row flex-col">
            <div className="md:w-3/5 w-full">
              <div className="w-full flex-col md:h-screen">
                <div className="px-10 py-2 md:h-1/2 bg-yellow-500 rounded-2xl">
                  <div>
                    <div className="text-black text-5xl">
                      <span className="text-7xl mt-3">Automated</span> &nbsp;
                      <p className="mt-3">
                        Asset &nbsp;{" "}
                        <span className="text-6xl">Investment</span> &nbsp;
                        Strategy
                      </p>
                      <p className="mt-3">Platform</p>
                      <p className="mt-3">powered by </p>
                      <p className="mt-3 text-6xl text-blue-800">
                        Chainlink , &nbsp;
                        <span className="text-black text-3xl">Superfluid</span>{" "}
                        &nbsp;
                        <span className="text-black text-3xl">
                          and &nbsp; Uniswap V3 .
                        </span>
                      </p>
                    </div>
                  </div>
                </div>
                <div className="flex md:h-1/2 md:flex-row flex-col mt-3 w-full">
                  <div
                    onClick={() => router.push("/dca")}
                    className="px-7 py-2 md:mr-2 bg-white md:mt-0 mt-3 md:w-1/2 w-full rounded-2xl border-4 hover:border-yellow-500 cursor-pointer"
                  >
                    <p className="text-black text-4xl">
                      Dollar Cost Average{" "}
                      <span className="text-yellow-500">Strategy</span>
                    </p>
                    <p className="mt-2">
                      Dollar Cost averaging is an investement strategy where the
                      user buys an asset at certain time intervals to reduce
                      risks , the assets is bought at different prices in small
                      amounts to average the out the price.
                    </p>
                    <p className="mt-2 text-2xl">
                      Our Platform streamlines the process with just one click,
                      putting your investing portfolio on auto pilot with &nbsp;{" "}
                      <span className="text-blue-600">Chainlink .</span>
                    </p>
                  </div>
                  <div
                    onClick={() => router.push("/rangeorder")}
                    className="px-10 py-2 md:ml-2 bg-white border-4 border-white hover:border-yellow-500 cursor-pointer md:mt-0 mt-3 md:w-1/2 w-full rounded-2xl"
                  >
                    <p className="text-black text-4xl">
                      Range <span className="text-yellow-500">Orders</span>
                    </p>
                    <p className="mt-3 text-balck">
                      {" "}
                      Range Orders is a strategy to reduce the impact of
                      volatility by spreading out your assets over time so
                      you're not buying shares at a high point for prices.
                    </p>
                    <p className="mt-1 text-black">
                      So with our one click solution
                    </p>
                    <p className="text-black text-2xl">
                      Don't have a <span className="text-yellow-500">FOMO</span>{" "}
                      of buying assets on a higher price
                    </p>
                    <p className=" text-black text-xl">
                      when your friends bought it a lower price .
                    </p>
                  </div>
                </div>
              </div>
            </div>
            <div className="md:w-2/5 w-full">
              <div className="w-full md:h-screen">
                <div
                  onClick={() => router.push("/clmmanager")}
                  className="px-10 py-2 md:mr-2 border-4 border-white hover:border-yellow-500 cursor-pointer md:mx-5 mx-0 mt-5 md:mt-0 rounded-2xl md:h-full"
                >
                  <p className="text-white text-5xl mt-2 tracking-wider">
                    <span className="text-yellow-500">Automating </span>Yield by
                    Investing in{" "}
                    <span className="text-yellow-500"> UniSwap v3.</span>
                  </p>
                  {/* <p className="text-2xl text-white mt-10 tracking-wider">Probably Ethereum's <span className="text-yellow-500 text-3xl">First</span> </p> */}
                  <p className="text-4xl tracking-wider text-yellow-500 mt-2">
                    Concentrated Liquidity Fully Automated Manager .
                  </p>
                  <p className="mt-7 text-2xl text-white tracking-wider">
                    Our platform streamlines everything from{" "}
                    <span className="text-yellow-500">investing</span> an asset
                    to changing the price range to provide{" "}
                    <span className="text-yellow-500 text-3xl">
                      5 X Profit{" "}
                    </span>{" "}
                    than an AMM to withdrawing the profit and sending it to you,
                    in{" "}
                    <span className="text-yellow-500 text-3xl">
                      just one simple click
                    </span>{" "}
                    using{" "}
                    <span className="text-blue-500 text-4xl">ChainLink .</span>
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Homepage;
