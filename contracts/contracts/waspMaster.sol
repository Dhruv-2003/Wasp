// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol';

// Tasks
// - fetch current price
// - calculate ticks
// - findTick
// - mintPosition
// - burnPosition

contract waspMaster is IUniswapV3Pool {

    function getPrice(address tokenIn, address tokenOut, uint256 fee)
        external
        view
        returns (uint160)
    {
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(tokenIn, tokenOut, fee);
        (uint160 sqrtPriceX96,,,,,,) =  pool.slot0();
        return sqrtPriceX96;
    }

   function calculateTicks(address _tokenIn, address _tokenOut) public returns(int24){
        uint160 _sqrtPriceX96 = getPrice(_tokenIn, _tokenOut);
        int24 tick = TickMath.getTickAtSqrtRatio(_sqrtPriceX96);
        return tick;
    }

    function findTick() public returns(int24, int24) {

    }

    //The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    //******* But how does the user pay and what amount ? *******// 
    function mintPosition( address owner,
        int24 _tickLower,
        int24 _tickUpper,
        uint128 _amount,
        bytes calldata _data) external payable returns(uint256,uint256){
        require(_amount != 0);
        (_tickLower, _tickUpper) = findTick();
        (uint256 amount0, uint256 amount1) = IUniswapV3PoolActions.mint(owner,_tickLower,_tickUpper,_amount,_data);
        return(amount0, amount1);
    }

    //Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    function burnPosition( int24 _tickLower,
        int24 _tickUpper,
        uint128 _amount) external payable returns(uint256,uint256){
            (_tickLower, _tickUpper) = findTick();
            (uint256 amount0, uint256 amount1) = IUniswapV3PoolActions.burn(_tickLower,_tickUpper,_amount);
            return(amount0, amount1);
    }
}
