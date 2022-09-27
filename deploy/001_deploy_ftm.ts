import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const ibToken = "0x00a35FD824c717879BF370E70AC6868b95870Dfb";
  const anyCall = "0xC10Ef9F491C9B59f936957026020C321651ac078";
  const veIB = "0xBe33aD085e4a5559e964FA8790ceB83905062065";
  // TODO: fill in deployed contract address on op
  const receiver = "0xBe33aD085e4a5559e964FA8790ceB83905062065";
  const destChainId = 10; // optimism
  // usdcFeeDist, solidFeeDist, IBFeeDist
  const feeDistributors = ["0x31A1D83C715F4bd6fE7A26f1Ce279Cec15011AE9", "0xB634c662296a4BA117A422bFE6742B75989Bd714", "0x3Af7c11d112C1C730E5ceE339Ca5B48F9309aCbC"];
  let migration = await deploy("veMigration", {
    from: deployer,
    args: [ibToken, anyCall, veIB, receiver, destChainId, feeDistributors],
    log: true,
    contract: "veMigration",
  });
};
export default func;
func.tags = ["deploy-ftm"];
