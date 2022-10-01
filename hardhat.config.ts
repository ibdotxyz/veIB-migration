import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "hardhat-deploy";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "@openzeppelin/hardhat-upgrades";
dotenv.config();

let forkingUrl = "";

switch (process.env.TEST_FORK) {
  case "optimism":
    forkingUrl = `https://optimism-mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`;
    break;
  case "fantom":
    forkingUrl = "https://rpc.ftm.tools";
    break;
}
const hardhatNetworkConfig =
  forkingUrl == ""
    ? {}
    : {
        forking: {
          url: forkingUrl,
        },
      };
const config: HardhatUserConfig = {
  namedAccounts: {
    deployer: {
      default: 0, // here this will by default take the first account as deployer
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.10",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  networks: {
    hardhat: hardhatNetworkConfig,
    optimism: {
      url: `https://optimism-mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [`${process.env.DEPLOYER_PRIVATE_KEY}`],
    },
    ftmTest: {
      url: `https://rpc.testnet.fantom.network/`,
      accounts: [`${process.env.DEPLOYER_PRIVATE_KEY}`],
    },
    fantom: {
      url: `https://fantom.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [`${process.env.DEPLOYER_PRIVATE_KEY}`],
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [`${process.env.DEPLOYER_PRIVATE_KEY}`],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  verify: {
    etherscan: {
      apiKey: process.env.ETHERSCAN_API_KEY,
    },
  },
};

export default config;
