import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const ibToken = "0x00a35FD824c717879BF370E70AC6868b95870Dfb";
  const anyCall = "0xC10Ef9F491C9B59f936957026020C321651ac078";
  const veIB = ibToken;
  const sourceChainId = 250;
  const destChainId = 10;
  const feeDistributors = [];
  let migration = await deploy("veMigrationOP", {
    from: deployer,
    args: [ibToken, anyCall, veIB, sourceChainId, destChainId, feeDistributors],
    log: true,
    contract: "veMigration",
  });
};
export default func;
func.tags = ["deploy-op"];
