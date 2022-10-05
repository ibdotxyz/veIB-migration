import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer, ibToken, veIB, anyCall } = await getNamedAccounts();

  // TODO: fill in deployed contract address on op
  const srcChainId = 250;
  const destChainId = 10;
  // usdcFeeDist, solidFeeDist, IBFeeDist
  const feeDistributors = ["0x31A1D83C715F4bd6fE7A26f1Ce279Cec15011AE9", "0xB634c662296a4BA117A422bFE6742B75989Bd714", "0x3Af7c11d112C1C730E5ceE339Ca5B48F9309aCbC"];
  const receiver = "0xE836ac1F9Aa67e55E499A3eE000Ca249E019Ced5"; // veIbMigration on dest chain
  let migration = await deploy("veMigrationSrc", {
    from: deployer,
    args: [anyCall, veIB, receiver, srcChainId, destChainId, feeDistributors],
    log: true,
    contract: "veMigrationSrc",
  });
};
export default func;
func.tags = ["deploy-src"];
