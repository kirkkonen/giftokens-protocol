require('dotenv').config()
import "@nomicfoundation/hardhat-toolbox";
import { HardhatUserConfig } from "hardhat/types";

const alchemyGoerliApiKey = process.env.ALCHEMY_GOERLI_API_KEY;
const alchemySepoliaApiKey = process.env.ALCHEMY_SEPOLIA_API_KEY;
const privateKey = process.env.PRIVATE_KEY;

const config: HardhatUserConfig = {
  solidity: "0.8.18",
  networks: {
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${alchemyGoerliApiKey}`,
      accounts: [privateKey]
    },
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${alchemySepoliaApiKey}`,
      accounts: [privateKey]
    }
    // hardhat: {
    //   gas: 'auto',
    //   forking: {
    //     url: `https://eth-goerli.alchemyapi.io/v2/${alchemyApiKey}`,
    //   }
    // }
  }
};

export default config;
