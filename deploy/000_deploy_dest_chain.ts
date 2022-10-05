import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer, ibToken, veIB, anyCall } = await getNamedAccounts();
  const srcChainId = 250; // ftm 250
  const destChainId = 10; // optimism 10

  let migration = await deploy("veMigrationDest", {
    from: deployer,
    args: [ibToken, anyCall, veIB, srcChainId],
    log: true,
    contract: "veMigrationDest",
  });
};
export default func;
func.tags = ["deploy-dest"];
