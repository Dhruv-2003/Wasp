// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {INonfungiblePositionManager} from "./interfaces/INonFungiblePositionManager.sol";
import {IUniswapV3Factory} from "./interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "./interfaces/IUniswapV3Pool.sol";

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract clmExchange {
    IUniswapV3Factory public factory;
    INonfungiblePositionManager public nonfungiblePositionManager;

    uint public tokenId;
    uint public liquidity;
    address public token0;
    address public token1;
    address public owner;

    constructor(address _factory, address _positionManager) {
        factory = IUniswapV3Factory(_factory);
        nonfungiblePositionManager = INonfungiblePositionManager(
            _positionManager
        );
        owner = msg.sender;
    }

    function getPrice(
        address tokenIn,
        address tokenOut,
        uint24 fee
    ) public view returns (uint160, int24, int24) {
        IUniswapV3Pool pool = IUniswapV3Pool(
            factory.getPool(tokenIn, tokenOut, fee)
        );
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0();
        int24 tickSpacing = pool.tickSpacing();
        return (sqrtPriceX96, tick, tickSpacing);
    }

    function getRangeTicks(
        address _tokenIn,
        address _tokenOut,
        uint24 fee
    ) public view returns (int24 lowerTick, int24 upperTick, int24 meanTick, int24 tickSpaceRem) {
        (uint160 _sqrtPriceX96, int24 tick, int24 tickSpacing) = getPrice(
            _tokenIn,
            _tokenOut,
            fee
        );
        tickSpaceRem = tick % tickSpacing;
        meanTick = tick - tickSpaceRem;
        lowerTick = meanTick - (tickSpacing * 5) ;
        upperTick = meanTick + (tickSpacing * 5) ;
        // return (lowerTick, upperTick, meanTick, tickSpaceRem);
    }

    function mintPosition(
        address _tokenIn,
        address _tokenOut,
        uint24 fee,
        uint256 _amount0,
        uint256 _amount1,
        int24 _tickLower,
        int24 _tickUpper
    ) public payable returns (uint256 amount0, uint256 amount1) {
        // (int24 _tickLower, int24 _tickUpper) = getRangeTicks(
        //     _tokenIn,
        //     _tokenOut,
        //     fee
        // );

        // Approve the position manager
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amount0);
        IERC20(_tokenOut).transferFrom(msg.sender, address(this), _amount1);

        IERC20(_tokenIn).approve(address(nonfungiblePositionManager), _amount0);
        IERC20(_tokenOut).approve(
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

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager
            .mint(params);

        // Remove allowance and refund in both assets.
        if (amount0 < _amount0) {
            IERC20(_tokenIn).approve(address(nonfungiblePositionManager), 0);
            uint256 refund0 = _amount0 - amount0;
            IERC20(_tokenIn).transfer(msg.sender, refund0);
        }

        if (amount1 < _amount1) {
            IERC20(_tokenOut).approve(address(nonfungiblePositionManager), 0);
            uint256 refund1 = _amount1 - amount1;
            IERC20(_tokenOut).transfer(msg.sender, refund1);
        }
        // reduce the Approval and return the extra funds
    }

    // only Master
    function closePosition() external {
        // collect fees
        collectAllFees();
        // decreaseLiquidity to 0
        (uint amount0, uint amount1) = decreaseLiquidity();
        // burn the Position NFT
        burnPosition();
        // Send the funds to the owner
        _sendToOwner(amount0, amount1);
    }

    function decreaseLiquidity()
        public
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
                    tokenId: tokenId,
                    liquidity: 0, // decreasing it to 0
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });

        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(
            params
        );

        // _position.currentLiqReduced = true;
        // amount 0 and amount 1 are the amounts refunded by the pool
    }

    function collectAllFees()
        public
        returns (uint256 amount0, uint256 amount1)
    {
        // Caller must own the ERC721 position, meaning it must be a deposit

        // set amount0Max and amount1Max to uint256.max to collect all fees
        // alternatively can set recipient to msg.sender and avoid another transaction in `sendToOwner`
        // sent to owner itself
        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: owner,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = nonfungiblePositionManager.collect(params);

        // _position.fees0 = _position.fees0 + amount0;
        // _position.fees1 = _position.fees1 + amount1;

        // _position.currentFeesCollected = true;
    }

    //Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    // Only executed once the positions is reduces to 0 and fees collected (check)
    function burnPosition() public payable {
        nonfungiblePositionManager.burn(tokenId);

        // _position.currentPositionBurnt = true;
    }

    function withdraw(uint256 amount0, uint256 amount1) external {
        // check msg.sender
        _sendToOwner(amount0, amount1);
    }

    function _sendToOwner(uint256 amount0, uint256 amount1) internal {
        IERC20(token0).transfer(owner, amount0);

        IERC20(token1).transfer(owner, amount1);
    }

    function getPosition() public view {
        nonfungiblePositionManager.positions(tokenId);
    }
}
