import { ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";

/*

This script deploys FlashSwap on mainnet or testnet
If you want to use this FlashSwap - deploy it via: npx hardhat run scripts/1_deploy_flashswap.ts --network YOUR NETWORK NAME HERE

*/

// It is constants for default networks
const UNISWAP_ROUTER: string = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
const UNISWAP_FACTORY: string = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";

async function main(): Promise<void> {
  const FlashSwap: ContractFactory = await ethers.getContractFactory("FlashSwap");
  const flashSwap: Contract = await FlashSwap.deploy(UNISWAP_FACTORY, UNISWAP_ROUTER);
  await flashSwap.deployed();
  console.log("FlashSwap deployed successfully. Address:", flashSwap.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
