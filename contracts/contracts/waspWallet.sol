// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./waspMaster.sol";

// - checkUpkeep
// - performUpkeep
// - mint
// - collect
// - burn
// - withdraw
// - deposit

contract WaspWallet is AutomationCompatibleInterface {
    IUniswapV3Factory public factory;
    INonfungiblePositionManager public nonfungiblePositionManager;
    uint public tokenId;

    waspMaster.CLMOrder public _clmOrder;

    constructor(
        address _factory,
        address _positionManager,
        waspMaster.CLMOrder memory clmOrder
    ) {
        factory = IUniswapV3Factory(_factory);
        nonfungiblePositionManager = INonfungiblePositionManager(
            _positionManager
        );
        _clmOrder = clmOrder;
    }

    /*///////////////////////////////////////////////////////////////
                          Chainlink Automation
    //////////////////////////////////////////////////////////////*/

    function checkUpKeep()
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = checkConditions(
            _clmOrder.token0,
            _clmOrder.token1,
            _clmOrder.fee
        );
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        require(_clmOrder.tokenId != 0);
        burnPosition(_clmOrder.tokenId);
        collectAllFees();
        /// mint new position
        mintPosition(_clmOrder.token0,_clmOrder.token1,_clmOrder.fee, _clmOrder.owner, _clmOrder.liqAmount0, _clmOrder.liqAmount1);
        totalCLMOrders += 1 ;
    }

    /*///////////////////////////////////////////////////////////////
                           Extrass
    //////////////////////////////////////////////////////////////*/

    function checkConditions(
        address _tokenIn,
        address _tokenOut,
        uint24 fee
    ) internal view returns (bool) {
        (uint160 _newprice, int24 _newtick) = exchangeRouter.getPrice(
            _tokenIn,
            _tokenOut,
            fee
        );
        // (int24 _lowerTick,int24 _upperTick) = getRangeTicks(_tokenIn,_tokenOut, fee);
        require(_lowerTick < _upperTick);
        if (_lowerTick <= _newtick <= _upperTick) {
            return false;
        } else {
            return true;
        }
    }

    /*///////////////////////////////////////////////////////////////
                           Uniswap functions
    //////////////////////////////////////////////////////////////*/

    function getPrice(
        address tokenIn,
        address tokenOut,
        uint24 fee
    ) public view returns (uint160, int24) {
        IUniswapV3Pool pool = IUniswapV3Pool(
            factory.getPool(tokenIn, tokenOut, fee)
        );
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0();
        return (sqrtPriceX96, tick);
    }

    function getRangeTicks(
        address _tokenIn,
        address _tokenOut,
        uint24 fee
    ) public view returns (int24 lowerTick, int24 upperTick) {
        (uint160 _sqrtPriceX96, int24 tick) = getPrice(
            _tokenIn,
            _tokenOut,
            fee
        );
        lowerTick = tick - 500;
        upperTick = tick + 500;
        return (lowerTick, upperTick);
    }

    //The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    //******* But how does the user pay and what amount ? *******//
    function mintPosition(
        address _tokenIn,
        address _tokenOut,
        uint24 fee,
        address owner,
        uint256 _amount0,
        uint256 _amount1
    ) external payable returns (uint256 amount0, uint256 amount1) {
        // require(_amount != 0);
        (int24 _tickLower, int24 _tickUpper) = getRangeTicks(
            _tokenIn,
            _tokenOut,
            fee
        );

        // transfer tokens to contract
        TransferHelper.safeTransferFrom(
            _tokenIn,
            msg.sender,
            address(this),
            _amount0
        );
        TransferHelper.safeTransferFrom(
            _tokenOut,
            msg.sender,
            address(this),
            _amount1
        );

        // Approve the position manager
        TransferHelper.safeApprove(
            _tokenIn,
            address(nonfungiblePositionManager),
            _amount0
        );
        TransferHelper.safeApprove(
            _tokenOut,
            address(nonfungiblePositionManager),
            _amount1
        );

        // (uint256 amount0, uint256 amount1) = IUniswapV3PoolActions.mint(
        //     owner,
        //     _tickLower,
        //     _tickUpper,
        //     _amount,
        //     _data
        // );

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: _tokenIn,
                token1: _tokenOut,
                fee: fee,
                tickLower: _tickLower,
                tickUpper: _tickUpper,
                amount0Desired: _amount0,
                amount1Desired: _amount1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: owner,
                deadline: block.timestamp
            });

        (tokenId, , amount0, amount1) = nonfungiblePositionManager.mint(params);
        return (amount0, amount1);
    }

    //Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    function burnPosition(uint256 _tokenId) external payable {
        nonfungiblePositionManager.burn(_clmOrder.tokenId);
    }

    function collectAllFees()
        external
        returns (uint256 amount0, uint256 amount1)
    {
        // Caller must own the ERC721 position, meaning it must be a deposit

        // set amount0Max and amount1Max to uint256.max to collect all fees
        // alternatively can set recipient to msg.sender and avoid another transaction in `sendToOwner`
        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams({
                tokenId: _clmOrder.tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = nonfungiblePositionManager.collect(params);

        // send collected feed back to owner
        _sendToOwner(tokenId, amount0, amount1);
    }
}

interface IUniswapV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

interface IUniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function mint(
        MintParams memory params
    )
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function collect(
        CollectParams memory params
    ) external returns (uint256 amount0, uint256 amount1);

    function burn(uint256 tokenId) external;
}
