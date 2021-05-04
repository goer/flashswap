import { config as dotEnvConfig } from "dotenv";
dotEnvConfig();


// For debug and testing: npx hardhat run app/main.ts --network kovan
// For production: npx hardhat run app/main.ts --network mainnet????


import fs from "fs";
import glob from "glob";
import { ethers, Signer, ContractFactory, Contract, BigNumber, providers, Wallet } from "ethers";
const { formatEther, parseEther } = ethers.utils;
import type { TransactionResponse, TransactionReceipt, Log } from "@ethersproject/abstract-provider";
import type { TransactionReceiptWithEvents, ContractData } from "./types";


const addresses = {
  // addresses from Uniswap docs
  ROUTER: '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D', 
  FACTORY: '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f',
  WETH: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',

  ERC20: process.env.SHIT_COIN_ADDRESS || "",

}


async function main() {
  console.log(1);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
