import { Wallet } from "ethers";

// This is script is used to create a new wallet and get its address

function main() {
  const wallet: Wallet = Wallet.createRandom();
  console.log(`New wallet private key is ${wallet.privateKey}`);
  console.log(`New wallet public address is ${wallet.address}`);
}

main();
