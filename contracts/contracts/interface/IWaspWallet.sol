// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

interface IWaspEx {
    function getPrice(
        address tokenIn,
        address tokenOut,
        uint24 fee
    ) external view returns (uint160, int24);

    function getRangeTicks(
        address _tokenIn,
        address _tokenOut,
        uint24 fee
    ) external view returns (int24 lowerTick, int24 upperTick);

    function mintPosition(
        address _tokenIn,
        address _tokenOut,
        uint24 fee,
        address owner,
        uint256 _amount0,
        uint256 _amount1
    ) external payable returns (uint256 amount0, uint256 amount1);

    function burnPosition() external;

    function collectAllFees()
        external
        returns (uint256 amount0, uint256 amount1);
}
