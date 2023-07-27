import React, { useState } from "react";
import {
  useCreateRevenuePath,
  useR3vlClient,
  useBalances,
  useRevenuePathTiers,
  useWithdraw,
} from "@r3vl/sdk";
import {
  useAccount,
  useWalletClient,
  usePublicClient,
  useNetwork,
} from "wagmi";
import TierPath from "../components/tierPath";

// interface ICreateArgs {
//     walletList: string[][];
//     distribution: number[][];
//     tiers: { [token: 'ETH' | 'WETH' | 'DAI' | 'USDC']: BigNumberish }[]
//     name: string;
//     mutabilityEnabled: boolean;
//   }

function revpath() {
  const { address } = useAccount();
  const { chain } = useNetwork();
  const publicClient = usePublicClient();
  const { data: walletClient } = useWalletClient();
  //   const [createArgs, setCreateArgs] = useState();
  const [walletAddresses, setWalletAddresses] = useState();
  const [distrbutions, setDistrbutions] = useState();
  const [tierLimits, setTierLimits] = useState();
  const [revPathAddress, setRevPathAddress] = useState("");
  const [revPathName, setRevPathName] = useState();
  const [tokenAddress, setTokenAddress] = useState();

  useR3vlClient({
    chainId: chain?.id,
    provider: publicClient,
    signer: walletClient,
    initV2Final: true, // In case you want to create a "complex" Revenue Path with tiers
    initSimple: true, // For revenue paths with no additional tiers configuration
    apiKey: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx",
    // Api key is required so SDK can store and access data related to Revenue Path configuration
  });

  const handleWalletAddresses = (tier, walletIndex, walletAddress) => {
    walletAddresses[tier][walletIndex] = walletAddress;

    setWalletAddresses(walletAddresses);
  };

  const handleDistributions = (tier, distIndex, distribution) => {
    distrbutions[tier][distIndex] = distribution;

    setDistrbutions(distrbutions);
  };

  const handleCreateRevenuePath = async () => {
    const createArgs = {
      walletList: walletAddresses,
      distribution: distrbutions,
      tiers: tierLimits,
      name: revPathName,
      mutabilityEnabled: true,
    };
    console.log(createArgs);
    // await createRevenuePath(createArgs);
  };

  /** Create Rev Path */
  const { mutate: createRevenuePath } = useCreateRevenuePath();

  /** Balances */
  const { data: balances } = useBalances(
    revPathAddress,
    {
      walletAddress: address, // OPTIONAL - Address of specific user wallet
      isERC20: tokenAddress,
    },
    { enabled: !!address }
  ); /// show the Balances in the dashboard

  /** Tiers */
  const { data: tiers, isFetched: tiersFetched } =
    useRevenuePathTiers(revPathAddress);
  const tier = tiers?.[0] || {};
  /// For showing the info of all the tiers and distributions

  /** Withdraw */
  const withdraw = useWithdraw(revPathAddress);
  const handleWithdraw = () => {
    withdraw.mutate({
      walletAddress: address,
      isERC20: tokenAddress,
    });
  };

  /** ISSUES */
  // need a way to get the Rev path Address

  return (
    <div className="w-screen">
      <div className="mt-10 flex flex-col justify-center items-center mx-3 md:mx-0">
        <div className="md:w-1/3 w-full border-4 border-yellow-500 px-4 py-3 rounded-2xl">
          <div className="flex flex-col">
            <div>
              <p className="mx-3 text-yellow-500 text-xl">Reveel Path</p>
            </div>
            <div className="mx-3 mt-5">
              <p className="text-yellow-500 text-xl">Path Name</p>
            </div>
            <div className="mt-3 mx-3">
              <input
                onChange={(e) => setRevPathName(e.target.value)}
                type="text"
                placeholder="Revenue Path Name"
                className="w-full px-3 py-1 rounded-xl text-black"
              ></input>
            </div>
            {/* Need to create a separate component , setting wallet , distrbutions , with different tiers */}

            <TierPath
              handleWalletAddresses={handleWalletAddresses}
              handleDistributions={handleDistributions}
              //   tier={i}
            />
            <div className="flex justify-center items-center mt-8 mb-2">
              <button
                onClick={() => handleCreateRevenuePath()}
                className="bg-yellow-500 px-5 py-2 border border-white rounded-2xl text-black hover:scale-105 hover:bg-black hover:border-yellow-500 hover:text-white duration-200"
              >
                create Path
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default revpath;
