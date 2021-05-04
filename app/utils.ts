const {fs} = require("fs");
const {glob} = require("glob");
import { Signer, ContractFactory } from "ethers";
import type { ContractData } from "./types";

// Get a ContractFactory by a contract name from ./artifacts dir
export function getContractFactory(name: string, signer: Signer): ContractFactory {
  // Find all .json files with such name in ./artifacts
  const files: string[] = glob.sync(`./artifacts/**/${name}.json`);
  // Throw an exception if the number of files found isn't 1
  if (files.length == 0) throw `Contract ${name}.sol not found`;
  // Get the first path
  const path: string = files[0];
  // Read the file from path
  const file: Buffer = fs.readFileSync(path);
  // Parse the Buffer to ContractData
  const data: ContractData = JSON.parse(file.toString());
  // Load ContractFactory from the ContractData
  const factory: ContractFactory = new ContractFactory(data.abi, data.bytecode, signer);
  return factory;
}