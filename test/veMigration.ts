import { ethers } from "hardhat";
import { expect } from "chai";
import { Signer } from "ethers";
import { veMigration, MockERC20, MockFeeDistributor, MockVE, MockAnyCall } from "../typechain";
import { impersonateAccount } from "./testUtils";
import { SSL_OP_DONT_INSERT_EMPTY_FRAGMENTS } from "constants";

describe("veMigration test", function () {
  let owner: Signer;
  let ownerAddress: string;
  let nonOwner: Signer;
  let nonOwnerAddress: string;
  let ftmve: MockVE;
  let ftmMigration: veMigration;
  let opMigration: veMigration;

  beforeEach(async function () {
    const signers = await ethers.getSigners();
    owner = signers[0];
    ownerAddress = await owner.getAddress();
    nonOwner = signers[1];
    nonOwnerAddress = await nonOwner.getAddress();

    const veFactory = await ethers.getContractFactory("MockVE");
    const veMigrationFactory = await ethers.getContractFactory("veMigration");
    const ERC20Factory = await ethers.getContractFactory("MockERC20");
    const anycallFactory = await ethers.getContractFactory("MockAnyCall");
    const anyCall = await anycallFactory.deploy(ownerAddress);
    const anyCallAddress = anyCall.address;
    let destChainId = 0; // null

    // op setup
    const opIBToken = ERC20Factory.attach("0x00a35FD824c717879BF370E70AC6868b95870Dfb");
    const opve = await veFactory.deploy(opIBToken.address, opIBToken.address);
    opMigration = await veMigrationFactory.deploy(opIBToken.address, anyCallAddress, opve.address, ethers.constants.AddressZero, destChainId, []);

    // ftm setup
    const ftmIBToken = ERC20Factory.attach("0x00a35FD824c717879BF370E70AC6868b95870Dfb");
    ftmve = veFactory.attach("0xBe33aD085e4a5559e964FA8790ceB83905062065");
    const feeDistributors = ["0x31A1D83C715F4bd6fE7A26f1Ce279Cec15011AE9", "0xB634c662296a4BA117A422bFE6742B75989Bd714", "0x3Af7c11d112C1C730E5ceE339Ca5B48F9309aCbC"];
    destChainId = 10; // optimism
    ftmMigration = await veMigrationFactory.deploy(ftmIBToken.address, anyCallAddress, ftmve.address, opMigration.address, destChainId, feeDistributors);
  });
  describe("test veMigration", async function () {
    it("can initiate migrate", async function () {
      const tokenId = 500;
      const userAddress = "0xF61c82256584B73219bc5E81D0Dd87Aee08009b3";
      const user = await impersonateAccount(userAddress);
      await ftmve.connect(user).setApprovalForAll(ftmMigration.address, true);
      await expect(ftmMigration.connect(user).migrate([tokenId]))
        .to.emit(ftmMigration, "MigrationInitiated")
        .withArgs(userAddress, [tokenId]);
      expect(await ftmve.ownerOf(tokenId)).to.eq(await ftmMigration.nullAddress());
    });
    it.only("can execute migrate", async function () {
      const tokenId = 500;
      const userAddress = "0xF61c82256584B73219bc5E81D0Dd87Aee08009b3";
      const executeMigrationCallData = opMigration.interface.encodeFunctionData('executeMigration', [userAddress,[tokenId], [[ethers.utils.parseUnits("1","wei"), 60 * 60 * 24 * 7]]]);
      console.log("test\n", executeMigrationCallData);
      const callDataWithFunction = opMigration.interface.encodeFunctionData("anyExecute", [executeMigrationCallData]);
      console.log("testwith calldata\n", callDataWithFunction);
      await opMigration.anyExecute(callDataWithFunction, { gasLimit: 1000000 });
    });
  });
});
