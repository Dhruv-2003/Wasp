import React from "react";

const TierPath = (props) => {
  return (
    <div>
      {/* map the tier wallets */}
      <div className="mx-3 mt-5">
        <p className="text-yellow-500 text-xl">Tier</p>
      </div>
      <WalletData
        handleWalletAddresses={props.handleWalletAddresses}
        handleDistributions={props.handleDistributions}
        // index={i}
        // tier=props.tier
      />
    </div>
  );
};

const WalletData = (props) => {
  return (
    <div className="mt-3 mx-3">
      <input
        // onChange={(e) =>
        //   handleWalletAddresses(props.tier, props.index, e.target.value)
        // }
        onChange={(e) => props.handleWalletAddresses(1, 1, e.target.value)}
        type="text"
        placeholder="Wallet Address"
        className="w-full px-3 py-1 rounded-xl text-black"
      ></input>
      <input
        // onChange={(e) => handleDistributions(props.tier, props.index, e.target.value)}
        onChange={(e) => props.handleDistributions(1, 1, e.target.value)}
        type="text"
        placeholder="Amount"
        className="w-full px-3 py-1 rounded-xl text-black"
      ></input>
    </div>
  );
};

export default TierPath;
