// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {SuperTokenV1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
// import {CFAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";
import {ISuperfluid, ISuperToken, ISuperApp} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
// import {ISETH} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/tokens/ISETH.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import {AutomationRegistryInterface, State, Config} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

import "./dcaMaster.sol";

// Tasks
// Receiving stream
// Track a user's portfolio
// unwrap and Swap
// pay for Gelato's task - so all the task will be created from this

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

contract dcaWallet is Ownable, AutomationCompatibleInterface {
    using SuperTokenV1Library for ISuperToken;
    ISwapRouter public immutable swapRouter;
    uint24 public constant poolFee = 3000;
    uint160 sqrtPriceLimitX96 = 0;

    address public dcafManager;
    uint public dcafOrderId;
    // struct DCAfOrder {
    //     address creator;
    //     address wallet;
    //     address tokenIn; // to send
    //     address superToken; // token streamed
    //     address tokenOut; // to buy
    //     int96 flowRate;
    //     uint256 timePeriod;
    //     uint256 dcafFreq;
    //     uint256 lastTradeTimeStamp;
    //     uint256 creationTimeStamp;
    //     bool activeStatus;
    //     bytes32 task1Id;
    //     bytes32 task2Id;
    // }
    dCafProtocol.DCAfOrder public dcafOrder;
    uint public totalAmountTradedIn;
    uint public totalAmountTradedOut;

    LinkTokenInterface public immutable i_link;
    // address public immutable registrar;
    AutomationRegistryInterface public immutable i_registry;
    KeeperRegistrarInterface public immutable i_registrar;

    event dcaTask1Executed(address caller, uint timestamp);
    event dcaSwapExecuted(
        uint amountIn,
        uint amountOut,
        uint timestamp,
        address tokenIn,
        address tokenOut
    );

    constructor(
        address _swapRouter,
        address _manager,
        uint _dcafOrderId,
        dCafProtocol.DCAfOrder memory _order,
        LinkTokenInterface _link,
        KeeperRegistrarInterface _registrar,
        AutomationRegistryInterface _registry
    ) {
        swapRouter = ISwapRouter(_swapRouter);
        dcafManager = _manager;
        dcafOrderId = _dcafOrderId;
        dcafOrder = _order;
        i_link = _link;
        i_registrar = _registrar;
        i_registry = _registry;
    }

    modifier onlyManager() {
        require(msg.sender == dcafManager, "NOT AUTHORISED");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                           Extras
    //////////////////////////////////////////////////////////////*/

    // function executeGelatoTask1() public {
    //     // DCAfOrder memory _dcafOrder = dcafOrders[dcafOrderId];
    //     require(dcafOrder.activeStatus, "Not Active");
    //     require(
    //         block.timestamp > dcafOrder.lastTradeTimeStamp + dcafOrder.dcafFreq,
    //         "Freq time not passed"
    //     );
    //     emit dcaTask1Executed(msg.sender, block.timestamp);
    //     // exectue beforeSwap
    //     beforeSwap();
    // }

    function beforeSwap() internal {
        // unwrap the token
        address superToken = dcafOrder.superToken;
        uint amountToUnWrap = ISuperToken(superToken).balanceOf(address(this));
        unwrapSuperToken(superToken, amountToUnWrap);

        // get the underlying token
        address underlyingToken = ISuperToken(superToken).getUnderlyingToken();
        require(underlyingToken == dcafOrder.tokenIn, "INVALID TOKEN");

        // intitiate swap
        _swapUniswapSingle(
            dcafOrder.tokenIn,
            dcafOrder.tokenOut,
            dcafOrder.creator,
            amountToUnWrap
        );
    }

    // save the total Trading stats
    function afterSwap(uint amountIn, uint amountOut) internal {
        dcafOrder.lastTradeTimeStamp = block.timestamp;
        totalAmountTradedIn += amountIn;
        totalAmountTradedOut += amountOut;

        emit dcaSwapExecuted(
            amountIn,
            amountOut,
            block.timestamp,
            dcafOrder.tokenIn,
            dcafOrder.tokenOut
        );
    }

    /*///////////////////////////////////////////////////////////////
                           Superfluid
    //////////////////////////////////////////////////////////////*/

    function wrapSuperToken(
        address token,
        address superTokenAddress,
        uint amountToWrap
    ) internal {
        // approving to transfer tokens from this to superTokenAddress
        IERC20(token).approve(superTokenAddress, amountToWrap);

        // wrapping and sent to this contract
        ISuperToken(superTokenAddress).upgrade(amountToWrap);
    }

    function unwrapSuperToken(
        address superTokenAddress,
        uint amountToUnwrap
    ) internal {
        // unwrapping
        ISuperToken(superTokenAddress).downgrade(amountToUnwrap);
    }

    // refund the underlying superTokens in case the stream is cancelled
    function refundSuperToken(address superToken) public onlyManager {
        require(!dcafOrder.activeStatus, "STILL ACTIVE");
        uint amount = ISuperToken(superToken).balanceOf(address(this));

        ISuperToken(superToken).transfer(dcafOrder.creator, amount);
    }

    /*///////////////////////////////////////////////////////////////
                           Chainlink Automation
    //////////////////////////////////////////////////////////////*/

    function checkUpkeep(
        bytes calldata checkData
    ) external override returns (bool upkeepNeeded, bytes memory performData) {
        if (
            block.timestamp >= dcafOrder.lastTradeTimeStamp + dcafOrder.dcafFreq
        ) {
            upkeepNeeded = true;
        } else {
            upkeepNeeded = false;
        }
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        require(dcafOrder.activeStatus, "Not Active");
        require(
            block.timestamp > dcafOrder.lastTradeTimeStamp + dcafOrder.dcafFreq,
            "Freq time not passed"
        );
        emit dcaTask1Executed(msg.sender, block.timestamp);
        // exectue beforeSwap
        beforeSwap();
    }

    function createTask1(
        uint frequency,
        bytes calldata encryptedEmail,
        uint linkAmount
    ) external onlyManager returns (uint256 taskId) {
        taskId = registerAndPredictID(
            "dcaTask1",
            encryptedEmail,
            address(this),
            999999,
            address(this),
            linkAmount / 2,
            bytes("0x")
        );
        dcafOrder.task1Id = taskId;
    }

    function createTask2(
        uint _dcafOrderId,
        uint timePeriod,
        bytes calldata encryptedEmail,
        uint linkAmount
    ) external onlyManager returns (uint256 taskId) {
        // encode : abi.encodeCall(dCafProtocol.executeGelatoTask2, (_dCafOrderId))
        bytes calldata checkData = abi.encode(_dcafOrderId);
        taskId = registerAndPredictID(
            "dcaTask2",
            encryptedEmail,
            address(dcafManager),
            999999,
            address(this),
            linkAmount / 2,
            checkData
        );
        dcafOrder.task2Id = taskId;
    }

    /*///////////////////////////////////////////////////////////////
                           Chainlink Automation
    //////////////////////////////////////////////////////////////*/

    function registerAndPredictID(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        uint96 amount,
        bytes calldata checkData
    ) public returns (uint256) {
        RegistrationParams memory params = RegistrationParams({
            name: name,
            encryptedEmail: encryptedEmail,
            upkeepContract: upkeepContract,
            gasLimit: gasLimit,
            adminAddress: adminAddress,
            checkData: checkData,
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

    function cancelUpkeep(uint taskId) public {
        i_registry.cancelUpkeep(taskId);
    }

    function depositLinkFunds(uint taskId, uint96 linkAmount) public {
        i_link.transferFrom(msg.sender, address(this), linkAmount);
        require(linkAmount >= 100000000000000000, "MIN LINK NOT SENT");
        i_link.approve(address(i_registry), linkAmount);
        i_registry.addFunds(taskId, linkAmount);
    }

    /*///////////////////////////////////////////////////////////////
                           Uniswap functions
    //////////////////////////////////////////////////////////////*/

    function _swapUniswapSingle(
        address tokenIn,
        address tokenOut,
        address recepient,
        uint256 amountIn
    ) internal returns (uint amountOut) {
        // Approve the router to spend the token
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

        // preparing the params
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: recepient,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);

        // then afterSwap() has to be called
        afterSwap(amountIn, amountOut);
    }
}
