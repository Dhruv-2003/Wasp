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
import "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
import {AutomationRegistryInterface, State, Config} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

import "./limitMaster.sol";

interface KeeperRegistrarInterface {
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

    function registerUpkeep(
        RegistrationParams memory requestParams
    ) external returns (uint256);
}

// Tasks
// Receiving stream
// Track a user's portfolio
// unwrap and Swap
// pay for Gelato's task - so all the task will be created from this
contract limitWallet is Ownable, AutomationCompatibleInterface {
    using SuperTokenV1Library for ISuperToken;
    ISwapRouter public immutable swapRouter;
    IQuoterV2 public immutable quoter;
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
    //     uint256 limitPrice;
    //     uint256 lastTradeTimeStamp;
    //     uint256 creationTimeStamp;
    //     bool activeStatus;
    //     bytes32 task1Id;
    //     bytes32 task2Id;
    // }
    limitCaf.DCAfOrder public dcafOrder;
    uint public totalAmountTradedIn;
    uint public totalAmountTradedOut;
    string web3FunctionHash;

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
        address _quoter,
        string memory _web3IPFSHash,
        address _manager,
        uint _dcafOrderId,
        dCafProtocol.DCAfOrder memory _order,
        LinkTokenInterface _link,
        KeeperRegistrarInterface _registrar,
        AutomationRegistryInterface _registry
    ) {
        swapRouter = ISwapRouter(_swapRouter);
        quoter = IQouterV2(_quoter);
        web3FunctionHash = _web3IPFSHash;
        dcafManager = _manager;
        dcafOrderId = _dcafOrderId;
        dcafOrder = _order;
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
    //     // require(
    //     //     block.timestamp > dcafOrder.lastTradeTimeStamp + dcafOrder.dcafFreq,
    //     //     "Freq time not passed"
    //     // );
    //     emit dcaTask1Executed(msg.sender, block.timestamp);
    //     // exectue beforeSwap
    //     beforeSwap();
    // }

    function checker() public {
        uint amountPrice = (1 ether) / 10;

        /// fetching the price for 1
        (uint256 amountOut, , , ) = _quoteSwapSingle(
            dcafOrder.tokenIn,
            dcafOrder.tokenOut,
            amountPrice
        );
        uint limitPrice = dcafOrder.limitPrice;
        // price in wei only against 1 ETHER unit of tokenIn
        canExec = ((amountOut * 10) == limitPrice) ? true : false;
        if (canExec) {
            execPayload = abi.encodeCall(this.executeGelatoTask, (orderId));
        } else {
            execPayload = abi.encode("Price Not matched");
        }
    }

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

    function depositLinkFunds() external payable {
        i_link.transferFrom(msg.sender, address(this), linkAmount);
        require(linkAmount >= 100000000000000000, "MIN LINK NOT SENT");
        i_link.approve(address(i_registry), linkAmount);
        i_registry.addFunds(taskId, linkAmount);
    }

    function registerAndPredictID1(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        uint96 amount
    ) public returns (uint256) {
        KeeperRegistrarInterface.RegistrationParams
            memory params = KeeperRegistrarInterface.RegistrationParams({
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

    function registerAndPredictID2(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        uint96 amount,
        uint dcafOrderId
    ) public returns (uint256) {
        KeeperRegistrarInterface.RegistrationParams
            memory params = KeeperRegistrarInterface.RegistrationParams({
                name: name,
                encryptedEmail: encryptedEmail,
                upkeepContract: upkeepContract,
                gasLimit: gasLimit,
                adminAddress: adminAddress,
                checkData: abi.encode(dcafOrderId),
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

    function createTask1(
        uint frequency,
        bytes calldata encryptedEmail,
        uint96 linkAmount
    ) external onlyManager returns (uint256 taskId) {
        taskId = registerAndPredictID1(
            "dcaTask1",
            encryptedEmail,
            address(this),
            999999,
            address(this),
            linkAmount / 2
        );
        dcafOrder.task1Id = taskId;
    }

    function createTask2(
        uint _dcafOrderId,
        uint timePeriod,
        bytes calldata encryptedEmail,
        uint96 linkAmount
    ) external onlyManager returns (uint256 taskId) {
        // encode : abi.encodeCall(dCafProtocol.executeGelatoTask2, (_dCafOrderId))
        taskId = registerAndPredictID2(
            "dcaTask2",
            encryptedEmail,
            address(dcafManager),
            999999,
            address(this),
            linkAmount / 2,
            _dcafOrderId
        );
        dcafOrder.task2Id = taskId;
    }

    function checkUpKeep(
        bytes calldata checkData
    ) external override returns (bool upkeepNeeded, bytes memory performData) {
        performData = checkData;
    }

    function performUpKeep(bytes calldata performData) external override {
        require(dcafOrder.activeStatus, "Not Active");
        // require(
        //     block.timestamp > dcafOrder.lastTradeTimeStamp + dcafOrder.dcafFreq,
        //     "Freq time not passed"
        // );
        emit dcaTask1Executed(msg.sender, block.timestamp);
        // exectue beforeSwap
        beforeSwap();
    }

    // address(0) for ETH
    // function withdrawGealtoFees(uint256 _amount, address _token) external {
    //     withdrawFunds(_amount, _token);
    // }

    // function createTask1(
    //     bytes calldata _web3FunctionArgsHex
    // ) external onlyManager returns (bytes32 taskId) {
    //     ModuleData memory moduleData = ModuleData({
    //         modules: new Module[](2),
    //         args: new bytes[](2)
    //     });

    //     // moduleData.modules[0] = Module.TIME;
    //     moduleData.modules[0] = Module.RESOLVER;
    //     moduleData.modules[1] = Module.PROXY;
    //     // moduleData.modules[2] = Module.SINGLE_EXEC;
    //     // moduleData.modules[1] = Module.WEB3_FUNCTION;
    //     // we can pass any arg we want in the encodeCall
    //     // moduleData.args[0] = _timeModuleArg(
    //     //     block.timestamp + frequency,
    //     //     frequency
    //     // );
    //     moduleData.args[0] = _resolverModuleArg(
    //         address(this),
    //         abi.encodeCall(this.checker, ())
    //     );
    //     moduleData.args[0] = _proxyModuleArg();
    //     // moduleData.args[2] = _singleExecModuleArg();
    //     // moduleData.args[1] = _web3FunctionModuleArg(
    //     //     web3FunctionHash,
    //     //     _web3FunctionArgsHex
    //     // );

    //     taskId = _createTask(
    //         address(this),
    //         abi.encodeWithSelector(this.executeGelatoTask1, ()),
    //         moduleData,
    //         address(0)
    //     );

    //     dcafOrder.task1Id = taskId;
    //     /// Here we just pass the function selector we are looking to execute
    //     // emit limitOrderTaskCreated(orderId, taskId);
    // }

    // we might need to pass extra args to create and store the TaskId
    // called in the manager
    // function createTask2(
    //     uint _dcafOrderId,
    //     uint timePeriod
    // ) external onlyManager returns (bytes32 taskId) {
    //     ModuleData memory moduleData = ModuleData({
    //         modules: new Module[](3),
    //         args: new bytes[](3)
    //     });

    //     moduleData.modules[0] = Module.TIME;
    //     moduleData.modules[1] = Module.PROXY;
    //     moduleData.modules[2] = Module.SINGLE_EXEC;

    //     // we can pass any arg we want in the encodeCall
    //     moduleData.args[0] = _timeModuleArg(
    //         block.timestamp + timePeriod,
    //         timePeriod
    //     );
    //     moduleData.args[1] = _proxyModuleArg();
    //     moduleData.args[2] = _singleExecModuleArg();

    //     taskId = _createTask(
    //         dcafManager,
    //         abi.encodeCall(dCafProtocol.executeGelatoTask2, (_dcafOrderId)),
    //         moduleData,
    //         address(0)
    //     );

    //     dcafOrder.task2Id = taskId;
    //     /// Here we just pass the function selector we are looking to execute

    //     // emit limitOrderTaskCreated(orderId, taskId);
    // }

    function cancelUpKepp(bytes32 taskId) public onlyManager {
        /// add restrictions
        i_registry.cancelUpkeep(taskId);
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

    function _quoteSwapMulti(
        bytes memory path,
        uint256 amountIn
    )
        internal
        returns (
            uint256 amountOut,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        )
    {
        (
            amountOut,
            sqrtPriceX96AfterList,
            initializedTicksCrossedList,
            gasEstimate
        ) = quoter.quoteExactInput(path, amountIn);
    }

    function _quoteSwapSingle(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    )
        internal
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        )
    {
        IQuoterV2.QuoteExactInputSingleParams memory params = IQuoterV2
            .QuoteExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                fee: poolFee,
                sqrtPriceLimitX96: sqrtPriceLimitX96
            });

        (
            amountOut,
            sqrtPriceX96After,
            initializedTicksCrossed,
            gasEstimate
        ) = quoter.quoteExactInputSingle(params);
    }
}
