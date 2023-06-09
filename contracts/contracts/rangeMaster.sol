// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

// Idea - Range Take Profit Orders
// So assuming user wants to earn some profit with a pair
// Considering the lower prices asset user has
// They will swap it for higher price now
// Open a liquidity position with this asset at a higher tick range
// When the price falls inside the , the assets is automatically swapped back
// Upkeep tasks just checks if the price has crossed the tick range
// Going ahead, it decreases the liquidity and collects back the swapped asset
// In this was user makes profit

// ## Tasks
// - createCLMOrder
// - cancelCLMOrder
// - registerUpkeep
// - cancelUpkeep
// - addFunds
// - withdraw funds
// - getOrder

import {AutomationRegistryInterface, State, Config} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
// import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import "./rangeWallet.sol";

struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    bytes checkData;
    bytes offchainConfig;
    uint96 amount;
}

interface KeeperRegistrarInterface {
    function registerUpkeep(
        RegistrationParams calldata requestParams
    ) external returns (uint256);
}

contract rangeMaster {
    /*///////////////////////////////////////////////////////////////
                          Mapping &  State Variables
    //////////////////////////////////////////////////////////////*/

    struct TPFOrder {
        address owner;
        address token0; // supplied
        address token1; // to buy
        uint amount0;
        uint amount1;
        uint sellPrice;
        uint24 fee;
        uint256 tokenId;
        uint256 upkeepId;
        uint256 creationTimestamp;
        address waspWallet;
    }
    uint public totalTPFOrders;
    mapping(uint => TPFOrder) public tpfOrders;

    address public factory;
    address public positionManager;
    address public swapRouter;

    // *********** Chainlink Automation Variables *********** //

    LinkTokenInterface public immutable i_link;
    // address public immutable registrar;
    AutomationRegistryInterface public immutable i_registry;
    KeeperRegistrarInterface public immutable i_registrar;

    // bytes4 registerSig = KeeperRegistrarInterface.register.selector;

    constructor(
        address _factory,
        address _positionManager,
        address _swapRouter,
        LinkTokenInterface _link,
        KeeperRegistrarInterface _registrar,
        AutomationRegistryInterface _registry
    ) {
        factory = _factory;
        positionManager = _positionManager;
        swapRouter = _swapRouter;
        i_link = _link;
        i_registrar = _registrar;
        i_registry = _registry;
        // i_registrar = registrar;
    }

    /*///////////////////////////////////////////////////////////////
                           Main functions
    //////////////////////////////////////////////////////////////*/

    function createTPFOrder(
        address token0,
        address token1,
        uint amount0,
        uint sellPrice,
        uint24 fee,
        uint96 linkAmount,
        bytes calldata email
    ) external returns (uint tpfOrderId) {
        totalTPFOrders += 1;
        tpfOrderId = totalTPFOrders;

        // Approval needs to be given to the master contract for token Usage
        TPFOrder memory _tpfOrder = TPFOrder({
            owner: msg.sender,
            token0: token0,
            token1: token1,
            amount0: amount0,
            amount1: 0,
            sellPrice: sellPrice,
            fee: fee,
            tokenId: 0,
            upkeepId: 0,
            creationTimestamp: block.timestamp,
            waspWallet: address(0)
        });
        (_tpfOrder.waspWallet, _tpfOrder.tokenId) = createAndMint(
            _tpfOrder,
            msg.sender
        );

        // approve the contract to use the link Token
        // transferred link to this contract
        {
            i_link.transferFrom(msg.sender, address(this), linkAmount);
            require(linkAmount >= 100000000000000000, "MIN LINK NOT SENT");

            _tpfOrder.upkeepId = registerAndPredictID(
                "wasp TPF Order",
                email,
                _tpfOrder.waspWallet,
                999999,
                address(this),
                linkAmount
            );
        }

        tpfOrders[tpfOrderId] = _tpfOrder;
    }

    function cancelTPFOrder(uint tpfOrderId) public {
        TPFOrder memory _tpfOrder = tpfOrders[tpfOrderId];
        require(msg.sender == _tpfOrder.owner, "ONLY CREATOR");

        // close the position
        rangeWallet(_tpfOrder.waspWallet).closePosition();

        // cancel the upkeep
        i_registry.cancelUpkeep(_tpfOrder.upkeepId);
        // i_registry.withdrawFunds(_tpfOrder.upkeepId, _tpfOrder.owner);
    }

    function createAndMint(
        TPFOrder memory tpfOrder,
        address creator
    ) internal returns (address _wallet, uint tokenId) {
        rangeWallet _waspWallet = new rangeWallet(
            factory,
            positionManager,
            swapRouter,
            tpfOrder,
            address(this)
        );
        _wallet = address(_waspWallet);

        // transfer the tokens to waspWallet directly
        IERC20(tpfOrder.token0).transferFrom(
            creator,
            address(_waspWallet),
            tpfOrder.amount0
        );

        // IERC20(tpfOrder.token1).transferFrom(
        //     creator,
        //     address(_waspWallet),
        //     tpfOrder.amount1
        // );

        // swapthe Funds , sent to wallet
        uint amountOut = _waspWallet._swapUniswapSingle(
            tpfOrder.token0,
            tpfOrder.token1,
            _wallet,
            tpfOrder.amount0,
            tpfOrder.fee
        );

        // Now Mint the new position for the Future tick
        (tokenId, , ) = _waspWallet.mintPosition(
            tpfOrder.token0,
            tpfOrder.token1,
            tpfOrder.fee,
            creator,
            0,
            amountOut,
            tpfOrder.sellPrice
        );
    }

    // *********** Chainlink Automation Functions *********** //
    // registry add. for sepolia: 0xE16Df59B887e3Caa439E0b29B42bA2e7976FD8b2
    // registrar add. for sepolia: 0x9a811502d843E5a03913d5A2cfb646c11463467A

    // make it internal
    function registerAndPredictID(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        uint96 amount
    ) public returns (uint256) {
        RegistrationParams memory params = RegistrationParams({
            name: name,
            encryptedEmail: encryptedEmail,
            upkeepContract: upkeepContract,
            gasLimit: gasLimit,
            adminAddress: adminAddress,
            checkData: "0x",
            offchainConfig: "0x",
            amount: amount
        });

        i_link.approve(address(i_registrar), params.amount);
        uint256 upkeepID = i_registrar.registerUpkeep(params);
        if (upkeepID != 0) {
            // DEV - Use the upkeepID however you see fit
            return upkeepID;
        } else {
            revert("auto-approve disabled");
        }
    }

    function cancelUpkeep(uint tpfOrderId) public {
        TPFOrder memory _tpfOrder = tpfOrders[tpfOrderId];
        require(msg.sender == _tpfOrder.owner, "ONLY CREATOR");
        i_registry.cancelUpkeep(_tpfOrder.upkeepId);
    }

    // only Called by wallets
    function cancelUpkeepTask(uint upKeepId) public {
        i_registry.cancelUpkeep(upKeepId);
    }

    function depositLinkFunds(uint tpfOrderId, uint96 linkAmount) public {
        TPFOrder memory _tpfOrder = tpfOrders[tpfOrderId];
        require(msg.sender == _tpfOrder.owner, "ONLY CREATOR");
        i_link.transferFrom(msg.sender, address(this), linkAmount);
        require(linkAmount >= 100000000000000000, "MIN LINK NOT SENT");
        i_link.approve(address(i_registry), linkAmount);
        i_registry.addFunds(_tpfOrder.upkeepId, linkAmount);
    }

    function withdrawLinkFunds(uint tpfOrderId) public {
        TPFOrder memory _tpfOrder = tpfOrders[tpfOrderId];
        require(msg.sender == _tpfOrder.owner, "ONLY CREATOR");
        // i_registry.withdrawFunds(_tpfOrder.upkeepId, _tpfOrder.owner);
    }
}
