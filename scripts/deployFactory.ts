import { ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";


async function main(): Promise<void> {
  const Factory: ContractFactory = await ethers.getContractFactory("Factory");
  let factory: Contract = await Factory.deploy();
  await factory.deployed();
  console.log("Factory of ERC20 deployed successfully. Address:", factory.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
