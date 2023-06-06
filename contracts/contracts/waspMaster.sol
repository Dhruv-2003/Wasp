// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
// import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

// import "@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol";

// Tasks
// - fetch current price
// - calculate ticks
// - mintPositionz
// - burnPosition

contract waspMaster is IUniswapV3Pool {
    IUniswapV3Factory public override factory;
    INonfungiblePositionManager public nonfungiblePositionManager;
    uint public tokenId;

    constructor(address _factory, address _positionManager) {
        factory = IUniswapV3Factory(_factory);
        nonfungiblePositionManager = INonfungiblePositionManager(
            _positionManager
        );
    }

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
    ) public returns (int24 lowerTick, int24 upperTick) {
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
    function burnPosition() external payable {
        nonfungiblePositionManager.burn(tokenId);
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
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = nonfungiblePositionManager.collect(params);

        // send collected feed back to owner
        // _sendToOwner(tokenId, amount0, amount1);
    }
}
