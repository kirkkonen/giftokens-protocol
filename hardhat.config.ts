require('dotenv').config()
import "@nomicfoundation/hardhat-toolbox";
import { HardhatUserConfig } from "hardhat/types";

const alchemyApiKey = process.env.ALCHEMY_API_KEY;
const goerliPrivateKey = process.env.GOERLI_PRIVATE_KEY;

const config: HardhatUserConfig = {
  solidity: "0.8.18",
  networks: {
    // goerli: {
    //   url: `https://eth-goerli.alchemyapi.io/v2/${alchemyApiKey}`,
    //   accounts: [goerliPrivateKey]
    // }
    hardhat: {
      forking: {
        url: `https://eth-goerli.alchemyapi.io/v2/${alchemyApiKey}`,
      }
    }
  }
};

export default config;
