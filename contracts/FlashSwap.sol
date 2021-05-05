// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';

import './interfaces/IUniswapV2Pair.sol';
import './libraries/UniswapV2Library.sol';
import './libraries/SafeMath.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IERC20.sol';

contract FlashSwap is IUniswapV2Callee {
    using SafeMath for uint;

    address private immutable _factory;
    address private immutable _router;
    address[] private _path;

    constructor(address factory, address router) public {
        _factory = factory;
        _router = router;
    }

    function startFlashLoan(uint amountIn, address[] calldata path, address baseToken) external {
        // `path` must not include `baseToken` address
        require(path.length >= 3, "FlashSwap: Length of this path has to be at least 3");
        require(path[0] == path[path.length - 1], "FlashSwap: First and last tokens must be the same token");

        // Save the path to use it in uniswapV2Call
        _path = path;

        address pair = UniswapV2Library.pairFor(_factory, path[0], baseToken);
        address token0 = IUniswapV2Pair(pair).token0();

        uint amount0 = path[0] == token0 ? amountIn : 0;
        uint amount1 = path[0] == token0 ? 0 : amountIn;

        // Make flashswap
        IUniswapV2Pair(pair).swap(
          amount0,
          amount1,
          address(this),
          bytes("any") // random `data` to trigger flash-swap
        );
        // Send all profit to this sender
        IERC20(path[0]).transfer(msg.sender, IERC20(path[0]).balanceOf(address(this)));
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        address rootToken;
        uint amounIn;
        {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        // Necassary to check that this msg.sender is a pair
        require(msg.sender == UniswapV2Library.pairFor(_factory, token0, token1), "FlashSwap: msg.sender is not a pair");
        // One of the amounts has to equal 0 because we need only one token to make a flashswap 
        // UniswapPair already checks that at least one greather than 0
        require(amount0 == 0 || amount1 == 0, "FlashSwap: Amount one of the tokens doesn't equal 0");
        // Use token1 and amount1 if amount0 == 0 else use token0 and amount0
        rootToken = amount0 == 0 ? token1 : token0;
        amounIn = amount0 == 0 ? amount1 : amount0;
        }
        IERC20(rootToken).approve(_router, amounIn);
        IUniswapV2Router02(_router).swapExactTokensForTokens(
            amounIn,
            amounIn, // Amount that will return back has to be greater than start amount
            _path,
            address(this),
            now + 10 minutes
        );
        // Calculate amountOut that will return to this pair.
        // amountOut = amounIn / 0.997 (+ 1 to avoid error)
        uint amountOut = amounIn.mul(1000).div(997).add(1);

        // Return tokens with fee back
        IERC20(rootToken).transfer(msg.sender, amountOut);
    }
}
