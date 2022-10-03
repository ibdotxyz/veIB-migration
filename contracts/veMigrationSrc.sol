// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IFeeDistributor.sol";
import "./interfaces/IAnyCall.sol";
import "./interfaces/IExecutor.sol";
import "./interfaces/IERC20.sol";

struct MigrationLock {
    uint256 amount;
    uint256 duration;
}

contract veMigrationSrc is Ownable {
    address public immutable ibToken;
    address public immutable anycallExecutor;
    address public immutable anyCall;
    address public immutable veIB;
    address public immutable receiver;
    uint256 public immutable srcChainId;
    uint256 public immutable destChainId;

    address[] public feeDistributors;

    uint256 public constant PAY_FEE_ON_DEST_CHAIN = 0; // PAID_ON_DEST = 0; PAID_ON_SRC = 2;
    address public constant nullAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant WEEK = 1 weeks;

    /// @notice emitted when migration is initiated on source chain
    /// @param user user address
    /// @param tokenIds tokenIds of the user
    event MigrationInitiated(address user, uint256[] tokenIds);

    /// @notice emitted when migration has failed on destination chain
    /// @param user user address
    /// @param oldTokenIds old tokenIds of the user
    event MigrationFailed(address user, uint256[] oldTokenIds);

    modifier onlyExecutor() {
        require(msg.sender == anycallExecutor, "Only executor can call this function");
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "Only this contract can call this function");
        _;
    }

    /// @notice Contract constructor, can be deployed on both the source chain and the destination chainz
    /// @param _ibToken ibToken address
    /// @param _anyCall anyCall address
    /// @param _veIB veIB address
    /// @param _feeDistributors feeDistributors address, only needed when deployed on source chain, set to [] when deployed on destination chain
    constructor(
        address _ibToken,
        address _anyCall,
        address _veIB,
        address _receiver,
        uint256 _srcChainId,
        uint256 _destChainId,
        address[] memory _feeDistributors
    ) {
        require(_ibToken != address(0), "ibToken address cannot be 0");
        require(_anyCall != address(0), "anyCall address cannot be 0");
        require(_veIB != address(0), "veIB address cannot be 0");
        require(_receiver != address(0), "receiver address cannot be 0");

        ibToken = _ibToken;
        anyCall = _anyCall;
        anycallExecutor = IAnyCall(_anyCall).executor();
        veIB = _veIB;
        receiver = _receiver;
        feeDistributors = _feeDistributors;
        srcChainId = _srcChainId;
        destChainId = _destChainId;
    }

    /// @notice function to initiate migration on source chain, it help users claim rewards from fee_distibutors
    ///         and then burn the veIB NFTs before initiating the anyCall to destination chain
    /// @param tokenIds array of tokenIds to migrate
    function migrate(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < feeDistributors.length; i++) {
            IFeeDistributor(feeDistributors[i]).claim_many(tokenIds);
        }
        MigrationLock[] memory migrationLocks = new MigrationLock[](tokenIds.length);
        uint256 oneWeekFromNow = block.timestamp + WEEK;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(IVotingEscrow(veIB).ownerOf(tokenIds[i]) == msg.sender, "You are not the owner of this token");
            IVotingEscrow.LockedBalance memory lockBalance = IVotingEscrow(veIB).locked(tokenIds[i]);
            uint256 duration = lockBalance.end >= oneWeekFromNow ? lockBalance.end - block.timestamp : WEEK;
            migrationLocks[i] = MigrationLock(uint256(uint128(lockBalance.amount)), duration);
            IVotingEscrow(veIB).transferFrom(msg.sender, nullAddress, tokenIds[i]);
        }
        bytes memory data = abi.encode(msg.sender, tokenIds, migrationLocks);
        // set fallBack address as the current address to log failures, if any
        IAnyCall(anyCall).anyCall(receiver, data, address(this), destChainId, PAY_FEE_ON_DEST_CHAIN);
        emit MigrationInitiated(msg.sender, tokenIds);
    }

    /// @notice function only callable by anyCall executor, if anyCall fails on OP, this function will be called by anyCall executor to log the failure
    /// @param data abi encoded data of the anyCall
    /// @return success true if migration is successful
    /// @return result return message
    function anyExecute(bytes calldata data) external onlyExecutor returns (bool success, bytes memory result) {
        (address callFrom, uint256 fromChainID, ) = IExecutor(anycallExecutor).context();
        require(callFrom == address(this) && fromChainID == srcChainId, "anyExecute can only be called for the purpose of logging failure with anyFallback");
        require(bytes4(data[:4]) == this.anyFallback.selector, "for logging with anyFallback, first 4 bytes have to be the function selector of anyFallback");

        // when migration fails on destination chain, log failure on source chain
        (address _initialCallTo, bytes memory _initialCallData) = abi.decode(data[4:], (address, bytes));
        this.anyFallback(_initialCallTo, _initialCallData);
        return (true, "");
    }

    /// @notice function to log failure on source chain, when the migration call on the destination chain is unsuccessful
    /// @param _initialCallTo initial call to address on the destination chain
    /// @param _initialCallData initial calldata sent to the destination chain
    function anyFallback(address _initialCallTo, bytes calldata _initialCallData) external onlySelf {
        require(_initialCallTo == receiver, "Incorrect receiver address");
        (address user, uint256[] memory oldTokenIds, ) = abi.decode(_initialCallData, (address, uint256[], IVotingEscrow.LockedBalance[]));
        emit MigrationFailed(user, oldTokenIds);
    }

    function getTokenIds(address user) external view returns (uint256[] memory) {
        uint256 balance = IERC721Enumerable(veIB).balanceOf(user);
        uint256[] memory ids = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            ids[i] = IERC721Enumerable(veIB).tokenOfOwnerByIndex(user, i);
        }
        return ids;
    }
}
