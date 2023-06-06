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
//

import {AutomationRegistryInterface, State, Config} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

interface KeeperRegistrarInterface {
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

abstract contract waspMaster is AutomationCompatibleInterface, WaspEx {
    // *********** Chainlink Automation *********** //

    LinkTokenInterface public immutable i_link;
    address public immutable registrar;
    AutomationRegistryInterface public immutable i_registry;
    bytes4 registerSig = KeeperRegistrarInterface.register.selector;

    constructor(
        LinkTokenInterface _link,
        address _registrar,
        AutomationRegistryInterface _registry
    ) {
        i_link = _link;
        registrar = _registrar;
        i_registry = _registry;
    }

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

    function checkUpKeep(
        bytes calldata checkData, address _tokenIn,
        address _tokenOut,
        uint24 fee
    ) external view returns (bool upkeepNeeded, bytes memory performData) {
        checkConditions(_tokenIn,_tokenOut, fee);
    }

    function performUpkeep(bytes calldata performData) external {
        burnPosition();
        collectAllFees();
    }

    uint160 public _newprice;
    int24 public _newtick;
    int24 public _upperTick;
    int24 public _lowerTick;

    function checkConditions(address _tokenIn,
        address _tokenOut,
        uint24 fee) view internal returns (bool){
        (uint160 _newprice, int24 _newtick ) = getPrice(_tokenIn,_tokenOut, fee);
        // (int24 _lowerTick,int24 _upperTick) = getRangeTicks(_tokenIn,_tokenOut, fee);

        // Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
        // The greatest tick for which the ratio is less than or equal to the input ratio
        _upperTick = TickMath.getTickAtSqrtRatio(_newprice);
        _lowerTick = _upperTick - (_newtick + 500);  // can also be directly 1000
        require(_lowerTick < _upperTick);
        if( _lowerTick <= _newtick <= _upperTick ){
            return false;
        }else{
            return true;
        }
    }
}
