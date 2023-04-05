require('dotenv').config()
require("@nomicfoundation/hardhat-toolbox");

const alchemyApiKey = process.env.ALCHEMY_API_KEY;
const goerliPrivateKey = process.env.GOERLI_PRIVATE_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.18",
  networks: {
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${alchemyApiKey}`,
      accounts: [goerliPrivateKey]
    }
  }
};