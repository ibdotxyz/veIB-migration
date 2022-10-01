import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const ibToken = "0x00a35FD824c717879BF370E70AC6868b95870Dfb";
  const anyCall = "0xC10Ef9F491C9B59f936957026020C321651ac078";
  const veIB = "";
  const srcChainId = 250; // ftm 250 ftm testNet 4002
  const destChainId = 10; // optimism 10, rinkeby 4

  let migration = await deploy("veMigrationDest", {
    from: deployer,
    args: [ibToken, anyCall, veIB, srcChainId],
    log: true,
    contract: "veMigrationDest",
  });
};
export default func;
func.tags = ["deploy-dest"];
