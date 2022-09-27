import { ethers, network } from "hardhat";
import "@nomiclabs/hardhat-waffle";

export async function getTimestamp() {
  // getting timestamp
  const blockNumBefore = await ethers.provider.getBlockNumber();
  const blockBefore = await ethers.provider.getBlock(blockNumBefore);
  const timestampBefore = blockBefore.timestamp;
  return timestampBefore;
}

export const impersonateAccount = async (address: string) => {
  const signer = await ethers.provider.getSigner(address);
  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [address],
  });
  return signer;
};

export const stopImpersonateAccount = async (address: string) => {
  await network.provider.request({
    method: "hardhat_stopImpersonatingAccount",
    params: [address],
  });
};

export const resetChain = async (blockNumber: BigInteger) => {
  await network.provider.request({
    method: "hardhat_reset",
    params: [
      {
        forking: {
          jsonRpcUrl: "https://mainnet-eth.compound.finance/",
          blockNumber: blockNumber,
        },
      },
    ],
  });
};
