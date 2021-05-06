## Description

FlashSwap is a smartcontract to make flashswaps with Uniswap. This mechanism allows you to make a swap if you only have enough money just to pay the fee.

* [Core concept](https://uniswap.org/docs/v2/core-concepts/flash-swaps/)
* [Detailed description](https://uniswap.org/docs/v2/smart-contract-integration/using-flash-swaps/)

## Contract

This contract takes addresses of the UniswapRouter and UnswapFactory during deploy, and provides method startFlashLoan to run flashswaps

### Constructor

```solidity
constructor(address factory, address router) public;
```

You can use your own Router and Factory or get actual address for default networks below:

UniswapV2Router02: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

UniswapV2Factory: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f

### startFlashLoan

```solidity
function startFlashLoan(uint amountIn, address[] memory path, address baseToken) external;
```

This method borrows tokens from uniswapPair, makes swap with Router, returns loans back and sends balance after deduction to the `msg.sender`.

* `amountIn` — amount of tokens that will be borrowed.
* `path` — an array of token addresses between which the swap will be performed in turn. First and last addresses **must** be the same to make a looped swap. Contract saves it to a private attribute `_path` to read it in the method `uniswapV2Call` that will be called next.
You can pass it using `data` argument  instead of an attribute, if you need it. `data` is a `bytes` type therefore if you want to pass addresses as an argument you need a library to convert list of addresses to bytes and vice versa. You can read about this [here](https://ethereum.stackexchange.com/a/90801). 
* `baseToken` — an address of a token that creates a liquidity containing pair with `path[0]` token. This token **must not** be in a `path` array, because UniswapPair doesn't allow to call swap method while some other swap is incomplete.

### Dependencies

Install dependencies of the package.json:

```bash
npm i -D
```

### Create config

Use _.env_ as a local config to set private options manually:

**Don't commit it to git! (keep it secret)**

```bash
cp .env.template .env
```

You should also register at  [Infura](https://infura.io/) and create new project there. 

After that set your Infura Project ID (from project settings) to _.env_

### Scripts

To run any script enter:

```bash
npx hardhat run path/to/script.ts --network network_name
```

#### Generate a wallet

Use the script to generate a new wallet with it's own private key and address:

```bash
npx hardhat run scripts/0_create_new_wallet.ts
```

Copy generated private key (or your own private key) to _.env_ config on the corresponding line.

Add some ETH to address of this wallet. For this you can use any _faucet_ for your network. For example [faucet.kovan.network](https://faucet.kovan.network)

#### Deploy the FlashSwap contract

A script to deploy the FlashSwap contract and to get it's address:

```bash
npx hardhat run scripts/1_deploy_flashswap.ts --network kovan
```

### Run tests

Hardhat allows you to execute tests in it's own network, but due to the fact that you need to interact with Uniswap, you should run it in a network where the Uniswap is. For example - Kovan.

```bash
npx hardhat test test/FlashSwap.ts --network kovan
```
