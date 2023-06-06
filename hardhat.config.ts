import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { hardhatArguments } from "hardhat";

import * as dotenv from "dotenv";
dotenv.config();

const accountSend: string = process.env.AccountSend!;
const apiKey: string = process.env.ApiKey!;
const sepoliaUrl = "https://rpc2.sepolia.org";
const mumbaiUrl = "https://rpc-mumbai.maticvigil.com";
const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  solidity: "0.8.18",
  networks: {
    sepolia: {
      url: sepoliaUrl,
      accounts: [accountSend],
      chainId: 11155111,
    },
    // mumbai: {

    // },
  },
  etherscan: {
    apiKey: apiKey,
  },
};

export default config;
