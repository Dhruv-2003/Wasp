import React, { useState } from "react";

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
      />
    </div>
  );
};

const WalletData = (props) => {
  const [inputList, setInputList] = useState([
    { walletAddress: "", amount: "" },
  ]);
  const [amount, setAmount] = useState("");

  const handleInputChange = (e, index) => {
    const { name, value } = e.target;
    const list = [...inputList];
    list[index][name] = value;
    setInputList(list);
  };

  // handle click event of the Remove button
  const handleRemoveClick = (index) => {
    const list = [...inputList];
    list.splice(index, 1);
    setInputList(list);
  };

  // handle click event of the Add button
  const handleAddClick = () => {
    setInputList([...inputList, { walletAddress: "", amount: "" }]);
  };

  return (
    <div className="mt-3 mx-3">
      {inputList.map((x, i) => {
        return (
          <div className="flex flex-col w-full">
            <input
              name="walletAddress"
              placeholder={`enter ${i + 1} walletAddress`}
              value={x.walletAddress}
              onChange={(e) => handleInputChange(e, i)}
              className="bg-white w-full px-3 py-1 rounded-xl text-black"
            />
            <input
              className="bg-white w-full px-3 py-1 rounded-xl text-black mt-4"
              name="amount"
              placeholder={`enter ${i + 1} amount`}
              value={x.amount}
              onChange={(e) => handleInputChange(e, i)}
            />
            <div className="">
              {inputList.length !== 1 && (
                <div className="w-full flex ">
                  <button
                    className="mt-3 mb-3 bg-yellow-500 text-black flex justify-center mx-auto px-4 py-1 rounded-xl"
                    onClick={() => handleRemoveClick(i)}
                  >
                    Remove
                  </button>
                </div>
              )}
              {inputList.length - 1 === i && (
                <button
                  className="bg-yellow-500 text-black flex justify-center mt-4 w-full py-2 rounded-xl"
                  onClick={handleAddClick}
                >
                  Add
                </button>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
};

export default TierPath;

// onChange={(e) => props.handleWalletAddresses(1, 1, e.target.value)}
// onChange={(e) => props.handleDistributions(1, 1, e.target.value)}
