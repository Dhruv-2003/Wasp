// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {INonfungiblePositionManager} from "./interfaces/INonFungiblePositionManager.sol";
import {IUniswapV3Factory} from "./interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "./interfaces/IUniswapV3Pool.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
// import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./waspMaster.sol";

// - checkUpkeep
// - performUpkeep
// - mints
// - collect
// - burn
// - withdraw
// - deposit

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

    function checkUpkeep(
        bytes calldata checkData
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = checkConditions(
            _clmOrder.token0,
            _clmOrder.token1,
            _clmOrder.fee
        );
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        require(_position.tokenId != 0);
        decreaseLiquidity();
        collectAllFees();
        burnPosition();
        /// mint new position
        mintPosition(
            _clmOrder.token0,
            _clmOrder.token1,
            _clmOrder.fee,
            _clmOrder.owner,
            _position.liqAmount0,
            _position.liqAmount1
        );
    }

    /*///////////////////////////////////////////////////////////////
                           Extrass
    //////////////////////////////////////////////////////////////*/

    function checkConditions(
        address _tokenIn,
        address _tokenOut,
        uint24 fee
    ) internal view returns (bool) {
        (uint160 _newprice, int24 _newtick, ) = getPrice(
            _tokenIn,
            _tokenOut,
            fee
        );
        // (int24 _lowerTick,int24 _upperTick) = getRangeTicks(_tokenIn,_tokenOut, fee);
        // require(_lowerTick < _upperTick);
        if (
            _position.lowerTick <= _newtick && _newtick <= _position.upperTick
        ) {
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
    ) public view returns (int24 lowerTick, int24 upperTick) {
        (uint160 _sqrtPriceX96, int24 tick, int24 tickSpacing) = getPrice(
            _tokenIn,
            _tokenOut,
            fee
        );
        int24 tickSpaceRem = tick % tickSpacing;
        int24 meanTick = tick - tickSpaceRem;
        lowerTick = meanTick - (tickSpacing * 5);
        upperTick = meanTick + (tickSpacing * 5);
        // return (lowerTick, upperTick, meanTick, tickSpaceRem);
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
        public
        payable
        returns (uint256 tokenId, uint256 amount0, uint256 amount1)
    {
        (int24 _tickLower, int24 _tickUpper) = getRangeTicks(
            _tokenIn,
            _tokenOut,
            fee
        );

        // Approve the position manager

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

        uint128 liquidity;
        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager
            .mint(params);

        _clmOrder.tokenId = tokenId;
        _clmOrder.waspWallet= address(this);

        _position = PositionData({
            tokenId: tokenId,
            liquidity: liquidity,
            lowerTick: _tickLower,
            upperTick: _tickUpper,
            liqAmount0: (amount0),
            liqAmount1: (amount1),
            fees0: (_position.fees0),
            fees1: (_position.fees1),
            currentPositionBurnt: false,
            currentFeesCollected: false,
            currentLiqReduced: false
        });

        // Remove allowance and refund in both assets.
        if (amount0 < _amount0) {
            IERC20(_tokenIn).approve(address(nonfungiblePositionManager), 0);
            uint256 refund0 = _amount0 - amount0;

            IERC20(_tokenIn).transfer(owner, refund0);
        }

        if (amount1 < _amount1) {
            IERC20(_tokenOut).approve(address(nonfungiblePositionManager), 0);
            uint256 refund1 = _amount1 - amount1;
            IERC20(_tokenOut).transfer(owner, refund1);
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
                    tokenId: _position.tokenId,
                    liquidity: _position.liquidity, // decreasing it to 0
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
        public
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
    function burnPosition() public payable {
        nonfungiblePositionManager.burn(_position.tokenId);

        _position.currentPositionBurnt = true;
    }

    function withdraw(uint256 amount0, uint256 amount1) external {
        // check msg.sender
        _sendToOwner(amount0, amount1);
    }

    function _sendToOwner(uint256 amount0, uint256 amount1) internal {
        IERC20(_clmOrder.token0).transfer(_clmOrder.owner, amount0);

        IERC20(_clmOrder.token1).transfer(_clmOrder.owner, amount1);
    }

    function getPosition() public view {
        nonfungiblePositionManager.positions(_position.tokenId);
    }
}
