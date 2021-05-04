// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './libraries/UniswapV2Library.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IERC20.sol';
import './interfaces/IUniswapV2Callee.sol';


/*

THE IDEA:

There are three tokens: A, B, C
Let's say that the current ratio between them is 1:10:100
We swap 1A -> 10B
After that for some reason (that we have no control of) the ratio between B and C changes to 9:100 (for example)
We swap 10B -> 110C(!!!)
We swap 110C -> 1.1A
0.1A returns to us as a profit
1A goes back to the pool

*/


contract FlashSwap is IUniswapV2Callee {
    IUniswapV2Factory immutable factoryV2;
    address immutable _factory;
    address immutable _router;
    address immutable token0;
    address immutable token1;
    address immutable _factoryAddr;
    address immutable _routerAddr;
    address private pair;
    address[] private _path;

    constructor(address factoryAddr, address routerAddr) public {
        _factoryAddr = factoryAddr;
        _routerAddr = routerAddr;
    }

    // This function takes path (array of token addresses) as an argument - so it has to be initialized before
    // Path should contain addresses of FOUR tokens like:
    // addressA, addressB, addressC, addressA (loop)
    function startFlashSwap(uint amount0, uint amount1, address[] memory path) external {
        // In our case 'amount1' doesn't affect anything
        require(path.length >= 3, "FlashSwap: length of path has to be at least 3");
        _path = path;
        // Get the pair address from the factory
        pair = IUniswapV2Factory(_factory).getPair(path[0], path[1]);
        // The first token of the pair
        token0 = IUniswapV2Pair(pair).token0();
        // First and last tokens of path must be the same
        require(token0 == path[0] && token0 == path[path.length - 1], "First and last tokens must be the same!");
        // Swap all tokens1
        IUniswapV2Pair(pair).swap(
          amount0,
          0, // Transaction shouldn't be reverted even if we remove zero tokens after the swap
          address(this), // Recepient of tokens is the same contract that calls what function
          bytes("somestring") // Non-zero length of these bytes triggers uniswapV2Call() below
        );
    }

    // sender = msg.sender
    // amount0 = amountIn
    // amount1 = amountOut
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        // Do all necassary checks
        token0 = IUniswapV2Pair(msg.sender).token0();
        token1 = IUniswapV2Pair(msg.sender).token1();
        assert(msg.sender == UniswapV2Library.pairFor(_factory, token0, token1));

        address rootToken = amount0 == 0 ? token1 : token0;
        uint amount = amount0 == 0 ? amount1 : amount0;
        
        // Approve transfer of ERC20 token via router
        IERC20(token0).approve(_router, amount0);
        // Router makes swaps for EACH(!) pair from the path
        IUniswapV2Router02(_router).swapExactTokensForTokens(
            amount0,
            amount0, // WARNING! minimum amount that will return back has to be greater than start amount (change that argument)
            _path,
            msg.sender,
            block.timestamp + 10 minutes
        );

        // At the very beginning we put amount0 tokens into the pool
        // So after all swaps we get amount0 + some more tokens
        // We return amount0 back to the pool
       (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(msg.sender).getReserves();
        uint amountIn = UniswapV2Library.getAmountIn(amount, reserve0, reserve1);
        IERC20(token0).transfer(pair, amountIn);
        // And send all profit to a sender
        IERC20(token0).transfer(sender, IERC20(token0).balanceOf(address(this)));
    }
}
