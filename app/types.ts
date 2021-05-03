import type { TransactionResponse, TransactionReceipt, Log } from "@ethersproject/abstract-provider";

export interface Event extends Log {
  event: string;
  args: Array<any>;
}

export interface TransactionReceiptWithEvents extends TransactionReceipt {
  events?: Array<Event>;
}

export interface ContractFactory<ContractType> {
  attach(address: string): ContractType;
  deploy(...args: any[]): ContractType;
}

export interface ContractData {
  _format: string,
  abi: Array<any>,
  contractName: string,
  bytecode: string,
  sourceName: string,
  deployedBytecode: string,
  linkReferences: object,
  deployedLinkReferences: object,
}

export interface CoinData {
  id: string,
  symbol: string,
  name: string,
}
