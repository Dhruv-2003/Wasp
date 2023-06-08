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
// - addFunds
// - withdraw funds
// - getOrder

import {AutomationRegistryInterface, State, Config} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
// import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

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
        uint256 upkeepId;
        uint256 creationTimestamp;
        address waspWallet;
    }
    uint public totalCLMOrders;
    mapping(uint => CLMOrder) public clmOrders;

    address public factory;
    address public positionManager;

    // *********** Chainlink Automation Variables *********** //

    LinkTokenInterface public immutable i_link;
    address public immutable registrar;
    AutomationRegistryInterface public immutable i_registry;
    // KeeperRegistrarInterface public immutable i_registrar;
    bytes4 registerSig = KeeperRegistrarInterface.register.selector;

    constructor(
        address _factory,
        address _positionManager,
        LinkTokenInterface _link,
        address _registrar,
        AutomationRegistryInterface _registry
    ) {
        factory = _factory;
        positionManager = _positionManager;
        i_link = _link;
        registrar = _registrar;
        i_registry = _registry;
        // i_registrar = registrar;
    }

    /*///////////////////////////////////////////////////////////////
                           Main functions
    //////////////////////////////////////////////////////////////*/

    function createCLMOrder(
        address token0,
        address token1,
        uint amount0,
        uint amount1,
        uint24 fee,
        uint linkAmount,
        bytes calldata email,
        bytes calldata checkData
    ) external returns (uint clmOrderId) {
        totalCLMOrders += 1;
        clmOrderId = totalCLMOrders;

        // Approval needs to be given to the master contract for token Usage
        CLMOrder memory _clmOrder = CLMOrder({
            owner: msg.sender,
            token0: token0,
            token1: token1,
            amount0: amount0,
            amount1: amount1,
            fee: fee,
            tokenId: 0,
            upkeepId: 0,
            creationTimestamp: block.timestamp,
            waspWallet: address(0)
        });
        (_clmOrder.waspWallet , _clmOrder.tokenId)= createAndMint(_clmOrder, msg.sender);

        // approve the contract to use the link Token
        // transferred link to this contract
        {
            i_link.transferFrom(msg.sender, address(this), linkAmount);
            require(linkAmount >= 100000000000000000, "MIN LINK NOT SENT");

            _clmOrder.upkeepId = registerAndPredictID(
                "wasp CLM Order",
                email,
                _clmOrder.waspWallet,
                30000,
                address(this),
                checkData,
                uint96(linkAmount),
                0
            );
        }

        // Create the Registery upkeep
        // RegistrationParams memory params = RegistrationParams({
        //     name: "wasp",
        //     encryptedEmail: abi.encode("contact@gmail.com"),
        //     upkeepContract: address(_waspWallet),
        //     gasLimit: 300000,
        //     adminAddress: address(this),
        //     checkData: "0x",
        //     offchainConfig: "0x",
        //     amount: linkAmount
        // });

        clmOrders[clmOrderId] = _clmOrder;
    }

    function cancelCLMOrder(uint clmOrderId) public {
        CLMOrder memory _clmOrder = clmOrders[clmOrderId];
        require(msg.sender == _clmOrder.owner, "ONLY CREATOR");

        // close the position
        WaspWallet(_clmOrder.waspWallet).closePosition();

        // cancel the upkeep
        i_registry.cancelUpkeep(_clmOrder.upkeepId);
        // i_registry.withdrawFunds(_clmOrder.upkeepId, _clmOrder.owner);
    }

    function createAndMint(
        CLMOrder memory clmOrder,
        address creator
    ) internal returns (address _wallet, uint tokenId) {
        WaspWallet _waspWallet = new WaspWallet(
            factory,
            positionManager,
            clmOrder
        );
        _wallet = address(_waspWallet);

        // transfer the tokens to waspWallet directly
        IERC20(clmOrder.token0).transferFrom(
            creator,
            address(_waspWallet),
            clmOrder.amount0
        );

        IERC20(clmOrder.token1).transferFrom(
            creator,
            address(_waspWallet),
            clmOrder.amount1
        );

        // Now Mint the new position for the current tick
        (tokenId, , ) = _waspWallet.mintPosition(
            clmOrder.token0,
            clmOrder.token1,
            clmOrder.fee,
            creator,
            clmOrder.amount0,
            clmOrder.amount1
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
        bytes calldata checkData,
        uint96 amount,
        uint8 source
    ) internal returns (uint256) {
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
            return upkeepID;
            // DEV - Use the upkeepID however you see fit
        } else {
            revert("auto-approve disabled");
        }
    }

    function cancelUpkeep(uint clmOrderId) public {
        CLMOrder memory _clmOrder = clmOrders[clmOrderId];
        require(msg.sender == _clmOrder.owner, "ONLY CREATOR");
        i_registry.cancelUpkeep(_clmOrder.upkeepId);
    }

    function depositLinkFunds(uint clmOrderId, uint96 linkAmount) public {
        CLMOrder memory _clmOrder = clmOrders[clmOrderId];
        require(msg.sender == _clmOrder.owner, "ONLY CREATOR");
        i_link.transferFrom(msg.sender, address(this), linkAmount);
        require(linkAmount >= 100000000000000000, "MIN LINK NOT SENT");
        i_link.approve(address(i_registry), linkAmount);
        i_registry.addFunds(_clmOrder.upkeepId, linkAmount);
    }

    function withdrawLinkFunds(uint clmOrderId) public {
        CLMOrder memory _clmOrder = clmOrders[clmOrderId];
        require(msg.sender == _clmOrder.owner, "ONLY CREATOR");
        // i_registry.withdrawFunds(_clmOrder.upkeepId, _clmOrder.owner);
    }
}
