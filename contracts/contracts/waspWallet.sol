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
    struct PositionData {
        uint256 tokenId;
        uint128 liquidity;
        int24 lowerTick;
        int24 upperTick;
        uint256 liqAmount0;
        uint256 liqAmount1;
        uint256 fees0;
        uint256 fees1;
        bool currentPositionBurnt;
        bool currentFeesCollected;
        bool currentLiqReduced;
    }

    PositionData public _position;

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
        burnPosition();
        collectAllFees();
        /// mint new position
        mintPosition(
            _clmOrder.token0,
            _clmOrder.token1,
            _clmOrder.fee,
            _clmOrder.owner,
            _clmOrder.liqAmount0,
            _clmOrder.liqAmount1
        );
        totalCLMOrders += 1;
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
    )
        external
        payable
        returns (uint256 tokenId, uint256 amount0, uint256 amount1)
    {
        (int24 _tickLower, int24 _tickUpper) = getRangeTicks(
            _tokenIn,
            _tokenOut,
            fee
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
                recipient: address(this), // tokens will be sent back to this contract only
                deadline: block.timestamp
            });

        uint128 liquidity;
        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager
            .mint(params);

        _position = positionData({
            tokenId: tokenId,
            liquidity: liquidity,
            lowerTick: _tickLower,
            upperTick: _tickUpper,
            liqAmount0: (_position.liqAmount0 + amount0),
            liqAmount1: (_position.liqAmount1 + amount1),
            fees0: (_position.fees0),
            fees1: (_position.fees1),
            currentPositionBurnt: false,
            currentFeesCollected: false,
            currentLiqReduced: false
        });
        return (amount0, amount1);
    }

    function decreaseLiquidity()
        external
        returns (uint256 amount0, uint256 amount1)
    {
        // caller must be the owner of the NFT
        // require(msg.sender == deposits[tokenId].owner, "Not the owner");
        // get liquidity data for tokenId

        // amount0Min and amount1Min are price slippage checks
        // if the amount received after burning is not greater than these minimums, transaction will fail
        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .DecreaseLiquidityParams({
                    tokenId: _position.tokenId,
                    liquidity: 0, // decreasing it to 0
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });

        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(
            params
        );

        _position.currentLiqReduced = true;
        // amount 0 and amount 1 are the amounts refunded by the pool
    }

    function collectAllFees()
        external
        returns (uint256 amount0, uint256 amount1)
    {
        // Caller must own the ERC721 position, meaning it must be a deposit

        // set amount0Max and amount1Max to uint256.max to collect all fees
        // alternatively can set recipient to msg.sender and avoid another transaction in `sendToOwner`
        // sent to owner itself
        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams({
                tokenId: _position.tokenId,
                recipient: _clmOrder.owner,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = nonfungiblePositionManager.collect(params);

        _position.fees0 = _position.fees0 + amount0;
        _position.fees1 = _position.fees1 + amount1;

        _position.currentFeesCollected = true;
    }

    //Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    // Only executed once the positions is reduces to 0 and fees collected (check)
    function burnPosition() external payable {
        nonfungiblePositionManager.burn(_position.tokenId);

        _position.currentPositionBurnt = true;
    }

    function _sendToOwner(uint256 amount0, uint256 amount1) internal {
        TransferHelper.safeTransfer(_position.token0, _clmOrder.owner, amount0);
        TransferHelper.safeTransfer(_position.token1, _clmOrder.owner, amount1);
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
    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
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

    function increaseLiquidity(
        IncreaseLiquidityParams params
    ) external returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    function decreaseLiquidity(
        DecreaseLiquidityParams params
    ) external returns (uint256 amount0, uint256 amount1);

    function collect(
        CollectParams memory params
    ) external returns (uint256 amount0, uint256 amount1);

    function burn(uint256 tokenId) external;
}
