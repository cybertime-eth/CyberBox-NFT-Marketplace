require("@nomiclabs/hardhat-waffle");
require('dotenv').config({path: '.env'});
require("@nomiclabs/hardhat-etherscan");
require('hardhat-deploy');

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

// Prints the Celo accounts associated with the mnemonic in .env
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "alfajores",
  networks: {
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: 50000000000,
      // gasLimit: 10000000
    },
    mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    alfajores: {
      url: "https://alfajores-forno.celo-testnet.org",
      // accounts: {
      //   // mnemonic: process.env.MNEMONIC,
      //   // path: "m/44'/52752'/0'/0"
        
      // },
      // chainId: 44787,
      // gas: 20000000
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: 50000000000,
    },
    celo: {
      url: "https://forno.celo.org",
      accounts: {
        mnemonic: process.env.MNEMONIC,
        path: "m/44'/52752'/0'/0"
      },
      chainId: 42220
    }
  },
  solidity: "0.8.0",
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: process.env.BSCSCAN_KEY
  }
};