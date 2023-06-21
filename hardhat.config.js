require('dotenv').config();

require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");
require('hardhat-contract-sizer');

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: '0.8.20',
    settings: {
      optimizer: {
        enabled: true,
        runs: 10_000,
      },
    },
  },

  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true
  },

  gasReporter: {
    currency: "USD",
    coinmarketcap: process.env.COIN_MARKET_CAP_API_KEY,
    showTimeSpent: true,
    enabled: true,
    token: "ETH"
  },
};
