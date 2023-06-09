// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./dcaWallet.sol";
import {SuperTokenV1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
// import {CFAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISuperfluid, ISuperToken, ISuperApp} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {ISETH} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/tokens/ISETH.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

// SUPERFLUID
// - Wrap ERC20 tokens -- user has erc20 tokens
// - Unwrap ERC20 tokens -- user has super tokenAddress
// - Create Stream by Operatoraq
// - Update Stream by Operator
// - Delete Stream by Operator
// - updateOperator permissions
// - AuitorizeFullOperator
// - Revoke Full Operator

// Dollar Cost Average
// - StartDCA - to start the dcaProcess, with rate, timePeriod, token and assetToBuy
// - updateDCA - update stream and tasks
// - cancelDCA - cancel all the task associated , cancel the stream and refund any extra amount we receive
// - refundExtraTokens - refund the token rcvd extra

// Uniswap
// - swap() - takes in a token for amount and returns back the other

// Gelato
// - createTask()
// - cancelTask()
// - checker()

// Extra
// - beforeSwap() - unwraps the token before swapping and call swap
// - afterSwap() -  send the exchanged tokens to the user directly
// - cancelDCATask() - after time period is over , it will cancel the task1 and the stream

contract dCafProtocol is
    AutomateTaskCreator,
    Ownable,
    AutomationCompatibleInterface
{
    using SuperTokenV1Library for ISuperToken;
    ISwapRouter public immutable swapRouter;
    uint24 public constant poolFee = 3000;
    uint160 sqrtPriceLimitX96 = 0;

    // mapping(address => bool) public accountList;
    address payable public automateAddress;

    // ISuperToken public token;

    struct DCAfOrder {
        address creator;
        address wallet;
        address tokenIn; // to send
        address superToken; // token streamed
        address tokenOut; // to buy
        int96 flowRate;
        uint256 timePeriod;
        uint256 dcafFreq;
        uint256 lastTradeTimeStamp;
        uint256 creationTimeStamp;
        bool activeStatus;
        uint256 task1Id;
        uint256 task2Id;
    }

    uint public totaldcafOrders;
    mapping(uint => DCAfOrder) public dcafOrders;

    event dcaOrderCreated(
        uint dcafOrderId,
        address dcaWallet,
        address creator,
        address superToken,
        uint256 task1Id,
        uint256 task2Id
    );
    event dcaOrderCancelled(uint dcafOrderId);
    event dcaTask2Executed(uint dcafOrderId, uint timeStamp, address caller);

    LinkTokenInterface public immutable i_link;
    // address public immutable registrar;
    AutomationRegistryInterface public immutable i_registry;
    KeeperRegistrarInterface public immutable i_registrar;

    constructor(
        address payable _automate,
        address _fundsOwner,
        address _swapRouter,
        address _factory,
        address _positionManager,
        LinkTokenInterface _link,
        KeeperRegistrarInterface _registrar,
        AutomationRegistryInterface _registry
    ) {
        factory = _factory;
        positionManager = _positionManager;
        i_link = _link;
        i_registrar = _registrar;
        i_registry = _registry;
        swapRouter = ISwapRouter(_swapRouter);
        automateAddress = _automate;
    }

    modifier onlyCreator(uint dcafOrderId) {
        address creator = dcafOrders[dcafOrderId].creator;
        require(msg.sender == creator, "NOT AUTHORISED");
        _;
    }

    modifier validId(uint dcafOrderId) {
        require(
            dcafOrderId != 0 && dcafOrderId <= totaldcafOrders,
            "NOT A VALID ORDER ID"
        );
        _;
    }

    error Unauthorized();

    /*///////////////////////////////////////////////////////////////
                           Dollar Cost Average
    //////////////////////////////////////////////////////////////*/
    // Need to send Native for Gelaot
    // Have Wrapped SuperToken
    // Assigned this contract as operator
    function createDCA(
        address superToken,
        address tokenOut,
        int96 flowRate,
        uint timePeriod, // only in sec
        uint dcafFreq, // only in sec
        uint96 linkAmount,
        bytes calldata encryptedEmail
    ) external payable returns (uint dcafOrderID) {
        // verify superToken , if valid or not
        totaldcafOrders += 1;
        dcafOrderID = totaldcafOrders;
        address tokenIn = ISuperToken(superToken).getUnderlyingToken();
        DCAfOrder memory _order = DCAfOrder({
            creator: msg.sender,
            wallet: address(0),
            tokenIn: tokenIn,
            superToken: superToken,
            tokenOut: tokenOut,
            flowRate: flowRate,
            timePeriod: timePeriod,
            dcafFreq: dcafFreq,
            lastTradeTimeStamp: block.timestamp,
            creationTimeStamp: block.timestamp,
            activeStatus: true,
            task1Id: 0,
            task2Id: 0
        });

        // create new dcaWallet for user
        dcaWallet _wallet = new dcaWallet(
            address(swapRouter),
            address(this),
            dcafOrderID,
            _order,
            i_link,
            i_registrar,
            i_registry
        );
        // storing the record
        _order.wallet = address(_wallet);

        // // deposit some fees
        // require(msg.value > 0, "SEND FEES FOR GELATO");
        // _wallet.depositGelatoFees{value: msg.value}();
        i_link.transferFrom(msg.sender, address(_wallet), linkAmount);

        //createStream to the wallet
        createStreamToContract(
            superToken,
            msg.sender,
            address(_wallet),
            flowRate
        );

        // deposit fees for Gelato in wallet

        // Task 1 to exectue the dcafOrder on the freq in the wallet
        uint256 task1Id = _wallet.createTask1(
            dcafFreq,
            encryptedEmail,
            linkAmount
        );
        _order.task1Id = task1Id;
        // Task 2 to close the dcafOrder later in the wallet
        uint256 task2Id = _wallet.createTask2(
            dcafOrderID,
            timePeriod,
            encryptedEmail,
            linkAmount
        );
        _order.task2Id = task2Id;
        dcafOrders[dcafOrderID] = _order;

        emit dcaOrderCreated(
            dcafOrderID,
            address(_wallet),
            msg.sender,
            superToken,
            task1Id,
            task2Id
        );
    }

    // What can be updated ??
    function updateDCA(uint dcafOrderId) external onlyCreator(dcafOrderId) {}

    function cancelDCA(uint dcafOrderId) external onlyCreator(dcafOrderId) {
        DCAfOrder memory _dcafOrder = dcafOrders[dcafOrderId];
        require(_dcafOrder.activeStatus, "Already Cancelled");
        require(
            block.timestamp >
                _dcafOrder.creationTimeStamp + _dcafOrder.timePeriod,
            "Time Period not crossed"
        );

        _dcafOrder.activeStatus = false;

        // cancel Task1 & 2 in the wallet contract
        dcaWallet(_dcafOrder.wallet).cancelTask(_dcafOrder.task1Id);
        dcaWallet(_dcafOrder.wallet).cancelTask(_dcafOrder.task2Id);

        // cancel the stream incoming
        deleteFlowToContract(
            _dcafOrder.superToken,
            _dcafOrder.creator,
            _dcafOrder.wallet
        );

        // refund the extra tokens lying
        dcaWallet(_dcafOrder.wallet).refundSuperToken(_dcafOrder.superToken);
        dcafOrders[dcafOrderId] = _dcafOrder;
        emit dcaOrderCancelled(dcafOrderId);
    }

    // only refunds in case the task was cancelled
    function refundDCA(uint dcafOrderId) external onlyCreator(dcafOrderId) {
        DCAfOrder memory _dcafOrder = dcafOrders[dcafOrderId];
        dcaWallet(_dcafOrder.wallet).refundSuperToken(_dcafOrder.superToken);
    }

    /*///////////////////////////////////////////////////////////////
                           Extras
    //////////////////////////////////////////////////////////////*/

    function checkUpkeep(
        bytes calldata checkData
    ) external override returns (bool upkeepNeeded, bytes memory performData) {
        uint dcafOrderId = abi.decode(checkData, (uint));
        DCAfOrder memory _dcafOrder = dcafOrders[dcafOrderId];
        if (
            block.timestamp >=
            _dcafOrder.creationTimeStamp + _dcafOrder.timePeriod
        ) {
            upkeepNeeded = true;
        } else {
            upkeepNeeded = false;
        }
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        uint dcafOrderId = abi.decode(checkData, (uint));
        DCAfOrder memory _dcafOrder = dcafOrders[dcafOrderId];
        require(_dcafOrder.activeStatus, "Already Cancelled");
        require(
            block.timestamp >
                _dcafOrder.creationTimeStamp + _dcafOrder.timePeriod,
            "Time Period not crossed"
        );
        _dcafOrder.activeStatus = false;
        cancelDCATask(
            _dcafOrder.wallet,
            _dcafOrder.task1Id,
            _dcafOrder.creator,
            _dcafOrder.superToken
        );
        dcafOrders[dcafOrderId] = _dcafOrder;
        emit dcaTask2Executed(dcafOrderId, block.timestamp, msg.sender);
    }

    // Add restrictions
    function executeGelatoTask2(uint dcafOrderId) public validId(dcafOrderId) {
        DCAfOrder memory _dcafOrder = dcafOrders[dcafOrderId];
        require(_dcafOrder.activeStatus, "Already Cancelled");
        require(
            block.timestamp >
                _dcafOrder.creationTimeStamp + _dcafOrder.timePeriod,
            "Time Period not crossed"
        );
        _dcafOrder.activeStatus = false;
        cancelDCATask(
            _dcafOrder.wallet,
            _dcafOrder.task1Id,
            _dcafOrder.creator,
            _dcafOrder.superToken
        );
        dcafOrders[dcafOrderId] = _dcafOrder;
        emit dcaTask2Executed(dcafOrderId, block.timestamp, msg.sender);
    }

    function cancelDCATask(
        address _wallet,
        bytes32 task1Id,
        address creator,
        address superToken
    ) internal {
        // cancel Task1 in the wallet contract
        dcaWallet(_wallet).cancelTask(task1Id);

        // cancel the stream incoming
        deleteFlowToContract(superToken, creator, _wallet);

        // // refund the extra tokens lying
        // dcaWallet(_wallet).refundSuperToken(superToken);
    }

    /*///////////////////////////////////////////////////////////////
                           Superfluid
    //////////////////////////////////////////////////////////////*/

    function wrapSuperTokenUser(
        address token,
        address superTokenAddress,
        uint amountToWrap
    ) external {
        // User has to approve before calling the wrapSuperToken
        // Getting tokens from the user
        IERC20(token).transferFrom(msg.sender, address(this), amountToWrap);

        // approving to transfer tokens from this to superTokenAddress
        IERC20(token).approve(superTokenAddress, amountToWrap);

        // wrapping and sent to this contract
        ISuperToken(superTokenAddress).upgrade(amountToWrap);

        // sending back the superToken to the user
        ISuperToken(superTokenAddress).transfer(msg.sender, amountToWrap);
    }

    function unwrapSuperTokenUser(
        address superTokenAddress,
        uint amountToUnwrap
    ) external {
        // sending supertoken from user to contract
        ISuperToken(superTokenAddress).transferFrom(
            msg.sender,
            address(this),
            amountToUnwrap
        );
        // unwrapping
        ISuperToken(superTokenAddress).downgrade(amountToUnwrap);

        // get token
        address underlyingToken = ISuperToken(superTokenAddress)
            .getUnderlyingToken();

        // transfer to user
        IERC20(underlyingToken).transferFrom(
            address(this),
            msg.sender,
            amountToUnwrap
        );
    }

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

    function createStreamToContract(
        address token,
        address from,
        address to,
        int96 flowRate
    ) internal {
        // if (
        //     !accountList[msg.sender] ||
        //     msg.sender != owner() ||
        //     msg.sender != address(this)
        // ) revert Unauthorized();

        ISuperToken(token).createFlowFrom(from, to, flowRate);
    }

    function updateFlowToContract(
        address token,
        address from,
        address to,
        int96 flowRate
    ) internal {
        // if (
        //     !accountList[msg.sender] ||
        //     msg.sender != owner() ||
        //     msg.sender != address(this)
        // ) revert Unauthorized();

        ISuperToken(token).updateFlowFrom(from, to, flowRate);
    }

    function deleteFlowToContract(
        address token,
        address from,
        address to
    ) internal {
        // if (
        //     !accountList[msg.sender] ||
        //     msg.sender != owner() ||
        //     msg.sender != address(this)
        // ) revert Unauthorized();

        ISuperToken(token).deleteFlowFrom(from, to);
    }

    // function updatePermissions(
    //     ISuperToken token,
    //     address flowOperator,
    //     bool allowCreate,
    //     bool allowUpdate,
    //     bool allowDelete,
    //     int96 flowRateAllowance
    // ) external {
    //     if (!accountList[msg.sender] && msg.sender != owner())
    //         revert Unauthorized();
    //     token.setFlowPermissions(
    //         token,
    //         flowOperator,
    //         allowCreate,
    //         allowUpdate,
    //         allowDelete,
    //         flowRateAllowance
    //     );
    // }

    // function fullAuthorization(
    //     ISuperToken token,
    //     address flowOperator
    // ) external {
    //     if (!accountList[msg.sender] && msg.sender != owner())
    //         revert Unauthorized();
    //     token.setFlowPermissions(flowOperator);
    // }

    // function revokeAuthorization(
    //     ISuperToken token,
    //     address flowOperator
    // ) external {
    //     if (!accountList[msg.sender] && msg.sender != owner())
    //         revert Unauthorized();
    //     token.revokeFlowPermissions(flowOperator);
    // }

    // updating stream permissions

    // the args will be decided on the basis of the web3 function we create and the task we add
    // @note - not ready to use , as we need to use a differnt Automate Contract for that
    // function createWeb3FunctionTask(
    //     string memory _web3FunctionHash,
    //     bytes calldata _web3FunctionArgsHex
    // ) internal {
    //     ModuleData memory moduleData = ModuleData({
    //         modules: new Module[](2),
    //         args: new bytes[](2)
    //     });

    //     moduleData.modules[0] = Module.PROXY;
    //     moduleData.modules[1] = Module.WEB3_FUNCTION;

    //     moduleData.args[0] = _proxyModuleArg();
    //     moduleData.args[1] = _web3FunctionModuleArg(
    //         _web3FunctionHash,
    //         _web3FunctionArgsHex
    //     );

    //     bytes32 id = _createTask(
    //         address(this),
    //         abi.encode(this.executeGelatoTask.selector),
    //         moduleData,
    //         address(0)
    //     );
    //     /// log the event with the Gelaot Task ID
    //     /// Here we just pass the function selector we are looking to execute
    // }

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
    }

    function _swapUniswapMulti(
        bytes memory path,
        address recepient,
        uint256 amountIn
    ) internal returns (uint amountOut) {
        // Approve the router to spend DAI.
        // TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);
        // path: abi.encodePacked(DAI, poolFee, USDC, poolFee, WETH9),
        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: path,
                recipient: recepient,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0
            });

        // Executes the swap.
        amountOut = swapRouter.exactInput(params);
    }
}
