import { ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";


async function main(): Promise<void> {
  const Router: ContractFactory = await ethers.getContractFactory("Router");
  let router: Contract = await Router.deploy();
  await router.deployed();
  console.log("Router deployed successfully. Address:", router.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
