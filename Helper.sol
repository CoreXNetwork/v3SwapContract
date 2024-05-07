// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "./v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "./v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "./v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./v3-core/contracts/libraries/TickMath.sol";

interface IERC20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}


contract CORExHelper  {

    address public _v3Factory = 0x20AD985053817E4bBF72f3C524e697F8A29f0283;
    address public _v3PositionManager = 0x6FC8a3c619e18113cbCa17625a4409182a774F28;

    struct V3LiquidityInfo {
        uint tokenId;
        address poolCode;
        uint160 currPriceX96;
        address token0;
        string token0Symbol;
        uint8 token0Decimals;
        address token1;
        string token1Symbol;
        uint8 token1Decimals;
        int24 tickLower;
        int24 tickUpper;
        uint reserve0;
        uint reserve1;
        uint24 fee;
        uint128 liquidity;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    function getAmountsFromLiquidity(uint256 tokenId) public view returns (uint amount0, uint amount1) {
        (,,address token0,address token1, uint24 fee,int24 tickLower,int24 tickUpper, uint128 liquidity,,,,) = INonfungiblePositionManager(_v3PositionManager).positions(tokenId);
        if(liquidity > 0) {
            address poolCode = IUniswapV3Factory(_v3Factory).getPool(token0, token1, fee);
            //LiquidityAmounts.getAmountsFromLiquidity()
            (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(poolCode).slot0();
            (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(sqrtPriceX96, TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickUpper), liquidity);
        }
    }

    function getLiquidityInfo(uint256 tokenId) public view returns (V3LiquidityInfo memory info) {
        (,,address token0,address token1, uint24 fee,int24 tickLower,int24 tickUpper, uint128 liquidity,,, uint128 tokensOwed0, uint128 tokensOwed1) = INonfungiblePositionManager(_v3PositionManager).positions(tokenId);
        info.tokenId = tokenId;
        info.token0 = token0;
        info.token1 = token1;
        info.fee = fee;
        info.tickLower = tickLower;
        info.tickUpper = tickUpper;
        info.liquidity = liquidity;
        info.tokensOwed0 = tokensOwed0;
        info.tokensOwed1 = tokensOwed1;

        if(liquidity > 0) {

            info.token0Symbol = IERC20(token0).symbol();
            info.token0Decimals = IERC20(token0).decimals();
            info.token1Symbol = IERC20(token1).symbol();
            info.token1Decimals = IERC20(token1).decimals();

            info.poolCode = IUniswapV3Factory(_v3Factory).getPool(token0, token1, fee);
            (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(info.poolCode).slot0();
            (uint amount0, uint amount1) = LiquidityAmounts.getAmountsForLiquidity(sqrtPriceX96, TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickUpper), liquidity);
            info.reserve0 = amount0;
            info.reserve1 = amount1;
            info.currPriceX96 = sqrtPriceX96;
        }
    }

    function getInAmount1(uint160 sqrtRatioX96,int24 tickLower,int24 tickUpper,uint256 inAmount0)external pure returns (uint256 inAmount1) {
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmount0(sqrtRatioX96,sqrtRatioBX96,inAmount0);
        uint256 amount1 = LiquidityAmounts.getAmount1ForLiquidity(sqrtRatioAX96,sqrtRatioX96, liquidity);
        return amount1;
    }

    function getInAmount0(uint160 sqrtRatioX96,int24 tickLower,int24 tickUpper,uint256 inAmount1)external pure returns (uint256 inAmount0) {
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmount1(sqrtRatioX96,sqrtRatioAX96,inAmount1);
        uint256 amount0 = LiquidityAmounts.getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
        return amount0;
    }



}