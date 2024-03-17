import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.24",

  networks: {
    sepolia: {
      url: `https://sepolia.rpc.thirdweb.com`,
      accounts: [
        "0xe430797523a3a7dabdbb2623b8eee0ca1343ffa5684c59ceedcff0f10a3e957b",
      ],
    },
    arbitrum_sepolia: {
      url: `https://arbitrum-sepolia.rpc.thirdweb.com`,
      accounts: [
        "0xe430797523a3a7dabdbb2623b8eee0ca1343ffa5684c59ceedcff0f10a3e957b",
      ],
    },
  },

  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY ?? "",
      arbitrum_sepolia: process.env.ARBISCAN_API_KEY ?? "",
    },

    customChains: [
      {
        network: "arbitrum_sepolia",
        chainId: 421614,
        urls: {
          apiURL: "https://api-sepolia.arbiscan.io/api",
          browserURL: "https://sepolia.arbiscan.io",
        },
      },
    ],
  },
};

export default config;
