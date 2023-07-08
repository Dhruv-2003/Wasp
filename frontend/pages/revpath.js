import React from "react";
import {
  useCreateRevenuePath,
  useR3vlClient,
  useBalances,
  useRevenuePathTiers,
  useWithdraw,
} from "@r3vl/sdk/hooks";
import {
  useAccount,
  useWalletClient,
  usePublicClient,
  useNetwork,
} from "wagmi";

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
  const [createArgs, setCreateArgs] = useState();
  const [revPathAddress, setRevPathAddress] = useState("");
  const [tokenAddress, setTokenAddress] = useState();

  useR3vlClient({
    chainId: chain?.id,
    provider: publicClient,
    signer: walletClient,
    initV2Final: true, // In case you want to create a "complex" Revenue Path with tiers
    initSimple: true, // For revenue paths with no additional tiers configuration
    apiKey: "",
    // Api key is required so SDK can store and access data related to Revenue Path configuration
  });

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
    <div>
      revpath
      <div>form</div>
      <button
        onClick={() => {
          createRevenuePath(createArgs);
        }}
      >
        Create the path
      </button>
    </div>
  );
}

export default revpath;
