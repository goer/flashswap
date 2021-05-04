// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import './libraries/UniswapV2Library.sol';
import './interfaces/IUniswapV2Factory.sol';
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
        require(path.length >= 3, "FlashSwap: length of path has to be at least 3");

        _path = path;
        address pair = IUniswapV2Factory(_factory).getPair(path[0], path[1]);

        // address token0 = IUniswapV2Pair(pair).token0();
        // require(token0 == path[0] && token0 == path[path.length - 1], "First and last tokens must be the same token0 of the first pair");

        IUniswapV2Pair(pair).swap(
          amount0,
          amount1,
          address(this),
          bytes("any") // random `data` to trigger flash-swap
        );
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        // Necassary to check that this msg.sender is a pair
        assert(msg.sender == UniswapV2Library.pairFor(_factory, token0, token1));
        assert(amount0 == 0 || amount1 == 0); // this strategy is unidirectional
        address rootToken = amount0 == 0 ? token1 : token0;
        uint amount = amount0 == 0 ? amount1 : amount0;

        IERC20(rootToken).approve(_router, amount);
        IUniswapV2Router02(_router).swapExactTokensForTokens(
            amount,
            amount, // Amount that will return back has to be greater than start amount
            _path,
            address(this),
            now + 10 minutes
        );

        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(msg.sender).getReserves();
        uint amountIn = UniswapV2Library.getAmountIn(amount, reserve0, reserve1);
        // uint256[] memory amountIn = UniswapV2Library.getAmountsIn(_factory, amount, _path);

        //amountIn[0] is it right index?
        IERC20(rootToken).transfer(msg.sender, amountIn);
        // Send all profit to a sender
        IERC20(rootToken).transfer(sender, IERC20(rootToken).balanceOf(address(this)));
    }
}
