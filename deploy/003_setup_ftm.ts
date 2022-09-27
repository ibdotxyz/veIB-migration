import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { get, execute, read } = deployments;
  const { deployer } = await getNamedAccounts();
  const receiver = "";
  const sender = "";
  await execute("veMigrationFTM", { from: deployer }, "setup", sender, receiver);
};
export default func;
func.tags = ["setup-op"];
