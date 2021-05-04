import { ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";


async function main(): Promise<void> {
  const Token: ContractFactory = await ethers.getContractFactory("TToken");
  let token: Contract = await Token.deploy();
  await token.deployed();
  console.log("Test ERC20 deployed successfully. Address:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
