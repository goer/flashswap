import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory, BigNumber } from "ethers";
import chai from "chai";
import { solidity } from "ethereum-waffle";
import { AddressZero } from "@ethersproject/constants";
import { getContractFactory } from "../app/utils";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import type { TransactionResponse, TransactionReceipt, Log } from "@ethersproject/abstract-provider";
import type { TransactionReceiptWithEvents } from "../app/types";

chai.use(solidity);
const { expect } = chai;
const { formatEther, parseEther } = ethers.utils;

// It is constants for default networks
const UNISWAP_ROUTER: string = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
const UNISWAP_FACTORY: string = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";

describe("FlashSwap", async () => {
  let accounts: SignerWithAddress[];
  let owner: SignerWithAddress;

  let TToken: ContractFactory;
  let FlashSwap: ContractFactory;
  let UniswapFactory: ContractFactory;
  let UniswapRouter: ContractFactory;
  let UniswapPair: ContractFactory;

  let weth: Contract;
  let dai: Contract;
  let usdt: Contract;
  let btc: Contract;
  let uniswapFactory: Contract;
  let uniswapRouter: Contract;

  before(async () => {
    accounts = await ethers.getSigners();
    owner = accounts[0];

    FlashSwap = getContractFactory("FlashSwap", owner);
    TToken = getContractFactory("TToken", owner);
    UniswapFactory = getContractFactory("IUniswapV2Factory", owner);
    UniswapRouter = getContractFactory("IUniswapV2Router02", owner);
    UniswapPair = getContractFactory("IUniswapV2Pair", owner);
  });

  beforeEach(async () => {
    weth = await TToken.deploy("WETH", "WETH", 18);
    dai = await TToken.deploy("DAI", "DAI", 18);
    usdt = await TToken.deploy("USDT", "USDT", 18);
    btc = await TToken.deploy("BTC", "BTC", 18);

    uniswapRouter = UniswapRouter.attach(UNISWAP_ROUTER);
    uniswapFactory = UniswapFactory.attach(UNISWAP_FACTORY);

    await weth.deployed();
    await dai.deployed();
    await usdt.deployed();
    await btc.deployed();

    await weth.mint(owner.address, parseEther("1000"));
    await dai.mint(owner.address, parseEther("4000"));
    await usdt.mint(owner.address, parseEther("2500"));
    await btc.mint(owner.address, parseEther("2000"));

    await weth.approve(uniswapRouter.address, parseEther("1000"));
    await dai.approve(uniswapRouter.address, parseEther("4000"));
    await usdt.approve(uniswapRouter.address, parseEther("2500"));
    await btc.approve(uniswapRouter.address, parseEther("2000"));
  });

  it("start_flash_swap", async () => {
    const flashSwap: Contract = await FlashSwap.deploy(uniswapFactory.address, uniswapRouter.address);
    await flashSwap.deployed();

    await uniswapRouter.addLiquidity(dai.address, weth.address, parseEther("1000"), parseEther("1000"), 0, 0, owner.address, Date.now() + 60000); // 1/1

    await uniswapRouter.addLiquidity(dai.address, usdt.address, parseEther("1000"), parseEther("1500"), 0, 0, owner.address, Date.now() + 60000); // 3/2
    await uniswapRouter.addLiquidity(dai.address, btc.address, parseEther("1000"), parseEther("1000"), 0, 0, owner.address, Date.now() + 60000); // 1/1
    const addTx: TransactionResponse = await uniswapRouter.addLiquidity(btc.address, usdt.address, parseEther("1000"), parseEther("1000"), 0, 0, owner.address, Date.now() + 60000); // 1/1
    await addTx.wait();

    const path: string[] = [dai.address, usdt.address, btc.address, dai.address];
    console.log(await flashSwap.startFlashLoan(parseEther("1000"), path, weth.address));
  });
});
