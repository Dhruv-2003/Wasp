import React, { useState } from "react";

const TierPath = (props) => {
  const [tierList, setTierList] = useState([
    [{ walletAddress: "", amount: "" }],
  ]);

  console.log(tierList);

  // handle click event of the Remove button
  const handleRemoveClick = (index) => {
    const list = [...tierList];
    list.splice(index, 1);
    setTierList(list);
  };

  // handle click event of the Add button
  const handleAddClick = () => {
    setTierList([...tierList, [{ walletAddress: "", amount: "" }]]);
  };

  const handleCreateRevenuePath = async () => {
    /// wallet List
    console.log(tierList);
    const list = [...tierList];
    let walletList = list;
    let distributions = list;
    await list.forEach(async (tierList, tier) => {
      await tierList.forEach((walletData, index) => {
        walletList[tier][index] = walletData.walletAddress;
        distributions[tier][index] = walletData.amount;
      });
    });

    // console.log(walletList);
    // console.log(distributions);
    /// distributions
    // props.handleCreateRevenuePath()
  };

  return (
    <div>
      {/* map the tier wallets */}
      {tierList.map((x, i) => {
        return (
          <div className="flex flex-col w-full">
            <div className="mx-3 mt-5">
              <p className="text-yellow-500 text-xl">Tier {i + 1}</p>
            </div>
            <div className="">
              {tierList.length !== 1 && i !== 0 && (
                <div className="w-full flex ">
                  <button
                    className="mt-3 mb-3 bg-yellow-500 text-black flex justify-center mx-auto px-4 py-1 rounded-xl"
                    onClick={() => handleRemoveClick(i)}
                  >
                    Remove
                  </button>
                </div>
              )}
              {tierList.length - 1 === i && (
                <button
                  className="bg-yellow-500 text-black flex justify-center mt-4 w-full py-2 rounded-xl"
                  onClick={handleAddClick}
                >
                  Add
                </button>
              )}
            </div>
            <WalletData
              tierList={tierList}
              setTierList={setTierList}
              tier={i}
            />
          </div>
        );
      })}
      <div className="flex justify-center items-center mt-8 mb-2">
        <button
          onClick={() => handleCreateRevenuePath()}
          className="bg-yellow-500 px-5 py-2 border border-white rounded-2xl text-black hover:scale-105 hover:bg-black hover:border-yellow-500 hover:text-white duration-200"
        >
          create Path
        </button>
      </div>
    </div>
  );
};

const WalletData = (props) => {
  const [amount, setAmount] = useState("");

  const handleInputChange = (e, index) => {
    const { name, value } = e.target;
    const list = [...props.tierList];
    console.log(list);
    list[props.tier][index][name] = value;
    props.setTierList(list);
  };

  // handle click event of the Remove button
  const handleRemoveClick = (index) => {
    const list = [...props.tierList];
    const tierList = props.tierList[props.tier];
    tierList.splice(index, 1);
    list[props.tier] = tierList;
    props.setTierList(list);
  };

  // handle click event of the Add button
  const handleAddClick = () => {
    const list = [...props.tierList];
    const currentTierList = props.tierList[props.tier];
    const newTierList = [...currentTierList, { walletAddress: "", amount: "" }];
    list[props.tier] = newTierList;
    props.setTierList(list);
  };

  return (
    <div className="mt-3 mx-3">
      {props.tierList[props.tier] &&
        props.tierList[props.tier].map((x, i) => {
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
                {props.tierList[props.tier].length !== 1 && (
                  <div className="w-full flex ">
                    <button
                      className="mt-3 mb-3 bg-yellow-500 text-black flex justify-center mx-auto px-4 py-1 rounded-xl"
                      onClick={() => handleRemoveClick(i)}
                    >
                      Remove
                    </button>
                  </div>
                )}
                {props.tierList[props.tier].length - 1 === i && (
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
