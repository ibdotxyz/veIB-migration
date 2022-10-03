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
    ibToken: {
      fantom: "0x00a35FD824c717879BF370E70AC6868b95870Dfb",
      optimism: "0x00a35FD824c717879BF370E70AC6868b95870Dfb",
      ftmTest: "0x534F54Ac33bA40fbA923309C22e2F9b32BF4747a",
      rinkeby: "0x779EeC7212aa2E35942B1422e12b44510E740F94",
    },
    veIB: {
      fantom: "0xBe33aD085e4a5559e964FA8790ceB83905062065",
      optimism: "",
      ftmTest: "0xb3a24E68E30e23A6A4668Ea826C9308E5DE89cAf",
      rinkeby: "0x3490A922E31a00cCD016Db5a2e897E0A5514a218",
    },
    anyCall: {
      fantom: "0xC10Ef9F491C9B59f936957026020C321651ac078",
      optimism: "0xC10Ef9F491C9B59f936957026020C321651ac078",
      ftmTest: "0xD7c295E399CA928A3a14b01D760E794f1AdF8990",
      rinkeby: "0x273a4fFcEb31B8473D51051Ad2a2EdbB7Ac8Ce02",
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
      accounts: process.env.DEPLOYER_PRIVATE_KEY == undefined ? [] : [`${process.env.DEPLOYER_PRIVATE_KEY}`],
    },
    ftmTest: {
      url: `https://rpc.testnet.fantom.network/`,
      accounts: process.env.DEPLOYER_PRIVATE_KEY == undefined ? [] : [`${process.env.DEPLOYER_PRIVATE_KEY}`],
    },
    fantom: {
      url: `https://fantom.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: process.env.DEPLOYER_PRIVATE_KEY == undefined ? [] : [`${process.env.DEPLOYER_PRIVATE_KEY}`],
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: process.env.DEPLOYER_PRIVATE_KEY == undefined ? [] : [`${process.env.DEPLOYER_PRIVATE_KEY}`],
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
