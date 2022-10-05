import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { get, execute, read } = deployments;
  const { deployer, ibToken, veIB, anyCall } = await getNamedAccounts();
  // TODO: fill in below
  const sender = ""; // veIbMigration on src chain;
  const prepaidFees = ethers.utils.parseEther("0.01");
  // END TODO
  let tx;
  tx = await execute("veMigrationDest", { from: deployer }, "setup", sender);
  console.log(tx.transactionHash, "setup");
  const anyCallContract = await ethers.getContractAt("AnyCallV6Proxy", anyCall);

  tx = await anyCallContract.deposit(sender, { value: prepaidFees, from: deployer });
  console.log(tx.transactionHash, "deposit");
};
export default func;
func.tags = ["setup-dest"];
