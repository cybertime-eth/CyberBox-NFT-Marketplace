// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");
const Web3 = require('web3')
const ContractKit = require('@celo/contractkit')
const web3 = new Web3('https://alfajores-forno.celo-testnet.org')
// const web3 = new Web3('https://celo-alfajores--rpc.datahub.figment.io/apikey/51de95307048d55477a26f9b0d4a7386')
const kit = ContractKit.newKitFromWeb3(web3)
const data = require('../artifacts/contracts/Daos.sol/Daos.json')
const Account = require('./celo_account');

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  // console.log("start");
  // const account = Account.getAccount()
  // console.log("Account.getAccount()", account.address);
  // kit.connection.addAccount(account.privateKey) 
  // console.log("kit.connection.addAccount");
  

  // let tx = await kit.connection.sendTransaction({
  //       from: account.address,
  //       data: data.bytecode
  // })
  // console.log("tx");
  //  const receipt = await tx.waitReceipt()
  // console.log(receipt)
  const dev = "0xD0841B274231a348d352e0786AFB1632A21B7705"

  const account = Account.getAccount()
  console.log("Account.getAccount()", account.address);

  const network = "testnet"
  console.log("start");
  const Daos = await ethers.getContractFactory("Daos");
  console.log("get");
  const daos = await Daos.deploy(dev);
  console.log("deployed");
  console.log({
    Daos: `npx hardhat verify --network ${network} ${daos.address} ${dev}`
  })
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
