// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

// Idea - Concentrated liquidity manager
// Portfolio wallet approach
// - You send a fixed amount as investement to the contract by creating an order
// - Contract will fetch the current price , Calculate the ticks and the range of liquidity
// - Calculate the Amounts to be sent , Open a Liquidity position for you
// - A task will be created to check the current position /  price , and acc range of the tick
// - if the current tick is out of the range , the current position is burnt
// - Also the fees are collected and sent to wallet contract
// - and consequently the new one is minted
// - The order can be cancelled too

// Idea - Range Orders + Limit Orders

// ## Tasks
// - createCLMOrder
// - cancelCLMOrder
// - registerUpkeep
// - cancelUpkeep
// - getOrder

import {AutomationRegistryInterface, State, Config} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
// import "./interface/IWaspEx.sol";
import "./waspWallet.sol";

interface KeeperRegistrarInterface {
    // mapping( )
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source,
        address sender
    ) external;
}

contract waspMaster {
    /*///////////////////////////////////////////////////////////////
                          Mapping &  State Variables
    //////////////////////////////////////////////////////////////*/

    struct CLMOrder {
        address owner;
        address token0;
        address token1;
        uint amount0;
        uint amount1;
        uint24 fee;
        uint256 tokenId;
        uint256 cretionTimestamp;
        address waspWallet;
    }
    uint public totalCLMOrders;
    mapping(uint => CLMOrder) public clmOrders;

    /*///////////////////////////////////////////////////////////////
                           Main functions
    //////////////////////////////////////////////////////////////*/

    function createCLMOrder(
        address token0,
        address token1,
        uint amount0,
        uint amount1,
        uint24 fee
    ) external returns (uint clmOrderId) {
        totalCLMOrders += 1;
        clmOrderId = totalCLMOrders;
        // Approval needs to be given to the master contract for token Usage

        CLMOrder memory _clmOrder = CLMOrder({
            owner: msg.sender,
            token0: token0,
            token1: token1,
            amount0: amount0,
            amoun1: amount1,
            fee: fee,
            tokenId: 0,
            creationTimestamp: block.timestamp,
            waspWallet: address(0)
        });

        WaspWallet _waspWallet = new WaspWallet();

        _clmOrder.waspWallet = address(_waspWallet);

        // transfer the tokens to waspWallet directly
        TransferHelper.safeTransferFrom(
            token0,
            msg.sender,
            address(_waspWallet),
            amount0
        );

        TransferHelper.safeTransferFrom(
            token1,
            msg.sender,
            address(_waspWallet),
            amount1
        );

        // Now Mint the new position for the current tick

        // Create the Registery upkeep

        clmOrders[clmOrderId] = _clmOrder;
    }

    // *********** Chainlink Automation Variables *********** //

    LinkTokenInterface public immutable i_link;
    address public immutable registrar;
    AutomationRegistryInterface public immutable i_registry;
    bytes4 registerSig = KeeperRegistrarInterface.register.selector;

    constructor(
        LinkTokenInterface _link,
        address _registrar,
        AutomationRegistryInterface _registry,
        address _waspEx
    ) {
        i_link = _link;
        registrar = _registrar;
        i_registry = _registry;
        exchangeRouter = IWaspEx(_waspEx);
    }

    // *********** Chainlink Automation Functions *********** //
    // registry add. for sepolia: 0xE16Df59B887e3Caa439E0b29B42bA2e7976FD8b2
    // registrar add. for sepolia: 0x9a811502d843E5a03913d5A2cfb646c11463467A

    function registerAndPredictID(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source
    ) public {
        (State memory state, , ) = i_registry.getState();
        uint256 oldNonce = state.nonce;
        bytes memory payload = abi.encode(
            name,
            encryptedEmail,
            upkeepContract,
            gasLimit,
            adminAddress,
            checkData,
            amount,
            source,
            address(this)
        );

        i_link.transferAndCall(
            registrar,
            amount,
            bytes.concat(registerSig, payload)
        );
        (state, , ) = i_registry.getState();
        uint256 newNonce = state.nonce;
        if (newNonce == oldNonce + 1) {
            uint256 upkeepID = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        address(i_registry),
                        uint32(oldNonce)
                    )
                )
            );
            // DEV - Use the upkeepID however you see fit
        } else {
            revert("auto-approve disabled");
        }
    }
}
