// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';

import './libraries/UniswapV2Library.sol';
import './uniswap/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IERC20.sol';

contract FlashSwap is IUniswapV2Callee {
    address private immutable _factory;
    address private immutable _router;
    address[] private _path;

    constructor(address factory, address router) public {
        _factory = factory;
        _router = router;
    }

    function startFlashLoan(uint amount0, uint amount1, address[] memory path) external {
        // `amount1` doesn't affect anything
        require(path.length >= 3, "FlashSwap: length of path has to be at least 3");
        //TODO: try to send this `path` to `data`. But how to convert an array to `bytes` type?
        _path = path;
        address pair = IUniswapV2Factory(_factory).getPair(path[0], path[1]);
        address token0 = IUniswapV2Pair(pair).token0();
        require(token0 == path[0] && token0 == path[path.length - 1], "First and last tokens must be the same token0 of the first pair");
        IUniswapV2Pair(pair).swap(
          amount0,
          // We need get only one token
          0, //amount1,
          address(this),
          bytes("any") // random `data` to trigger flash-swap
        );
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        // Necassary to check that this msg.sender is a pair
        assert(msg.sender == UniswapV2Library.pairFor(_factory, token0, token1));
        
        IERC20(token0).approve(_router, amount0);
        IUniswapV2Router02(_router).swapExactTokensForTokens(
            amount0,
            amount0, // minimum amount that will return back has to be greater than start amount
            _path,
            msg.sender,
            now + 10 minutes
        );

        uint amountIn = UniswapV2Library.getAmountsIn(_factory, amount0, _path);
        IERC20(token0).transfer(pair, amountIn);
        // Send all profit to a sender
        IERC20(token0).transfer(sender, IERC20(token0).balanceOf(address(this)));
    }
}
