// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IFeeDistributor.sol";
import "./interfaces/IAnyCall.sol";
import "./interfaces/IERC20.sol";

struct MigrationLock {
    uint256 amount;
    uint256 duration;
}

contract veMigration {
    address public immutable ibToken;
    address public immutable anycallExecutor;
    address public immutable anyCall;
    address public immutable veIB;
    address public immutable receiver;
    uint256 public immutable destChainId;

    address[] public feeDistributors;

    uint256 public constant PAY_FEE_ON_DEST_CHAIN = 0; // PAID_ON_DEST = 0; PAID_ON_SRC = 2;
    address public constant nullAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 internal constant WEEK = 1 weeks;

    /// @notice emitted when migration is initiated on source chain
    /// @param user user address
    /// @param tokenIds tokenIds of the user
    event MigrationInitiated(address user, uint256[] tokenIds);

    /// @notice emitted when migration is successful on destination chain
    /// @param user user address
    /// @param oldTokenIds old tokenIds of the user
    /// @param newTokenIds new tokenIds of the user after migration
    event MigrationCompleted(address user, uint256[] oldTokenIds, uint256[] newTokenIds);

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
    /// @param _receiver receiver address, only needed when deployed on source chain, set to 0x0 when deployed on destination chain
    /// @param _feeDistributors feeDistributors address, only needed when deployed on source chain, set to [] when deployed on destination chain
    /// @param _destChainId destination chainId, only needed when deployed on source chain, set to 0 when deployed on destination chain
    constructor(
        address _ibToken,
        address _anyCall,
        address _veIB,
        address _receiver,
        uint256 _destChainId,
        address[] memory _feeDistributors
    ) {
        require(_ibToken != address(0), "ibToken address cannot be 0");
        require(_anyCall != address(0), "anyCall address cannot be 0");
        require(_veIB != address(0), "veIB address cannot be 0");

        ibToken = _ibToken;
        anyCall = _anyCall;
        anycallExecutor = IAnyCall(_anyCall).executor();
        veIB = _veIB;
        // below only needed when deployed on source chain
        receiver = _receiver;
        feeDistributors = _feeDistributors;
        destChainId = _destChainId;
    }

    /// @notice function to initiate migration on source chain, it help users claim rewards from fee_distibutors
    ///         and then burn the veIB NFTs before initiating the anyCall to destination chain
    /// @param tokenIds array of tokenIds to migrate
    function migrate(uint256[] calldata tokenIds) external {
        require(receiver != address(0), "Receiver address cannot be 0");
        for (uint256 i = 0; i < feeDistributors.length; i++) {
            IFeeDistributor(feeDistributors[i]).claim_many(tokenIds);
        }
        MigrationLock[] memory migrationLocks = new MigrationLock[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(IVotingEscrow(veIB).ownerOf(tokenIds[i]) == msg.sender, "You are not the owner of this token");
            IVotingEscrow.LockedBalance memory lockBalance = IVotingEscrow(veIB).locked(tokenIds[i]);
            uint256 remainingDuration = lockBalance.end - block.timestamp;
            require(remainingDuration >= WEEK, "Lock duration is less than minimum lock duration");
            migrationLocks[i] = MigrationLock(uint256(uint128(lockBalance.amount)), remainingDuration);
            IVotingEscrow(veIB).transferFrom(msg.sender, nullAddress, tokenIds[i]);
        }
        bytes memory data = abi.encodeWithSelector(this.anyExecute.selector, abi.encode(tokenIds, migrationLocks, msg.sender));
        // set fallBack address as the current address to log failures, if any
        IAnyCall(anyCall).anyCall(receiver, data, address(this), destChainId, PAY_FEE_ON_DEST_CHAIN);
        emit MigrationInitiated(msg.sender, tokenIds);
    }

    /// @notice function only callable by anyCall executor, it will be called on destination chain and the source chain
    ///         upon a successful call on the dest chain, it will execute the normal migration flow
    ///         if such call fails, it will in turn call the anyCall executor to initiate a call on the source chain
    ///         with the function selector as anyFallback, which will then log the failure on the source chain
    /// @param data abi encoded data of the anyCall
    /// @return success true if migration is successful
    /// @return result return message
    function anyExecute(bytes calldata data) external onlyExecutor returns (bool success, bytes memory result) {
        bytes4 selector = bytes4(data[:4]);
        if (selector == this.anyExecute.selector) {
            // execute migration flow on destination chain
            executeMigration(data[4:]);
        } else if (selector == this.anyFallback.selector) {
            // when migration fails on destination chain, log failure on source chain
            (address _initialCallTo, bytes memory _initialCallData) = abi.decode(data[4:], (address, bytes));
            this.anyFallback(_initialCallTo, _initialCallData);
        } else {
            return (false, "unknown selector");
        }
        return (true, "");
    }

    /// @notice function to log failure on source chain, when the migration call on the destination chain is unsuccessful
    /// @param _initialCallTo initial call to address on the destination chain
    /// @param _initialCallData initial calldata sent to the destination chain
    function anyFallback(address _initialCallTo, bytes calldata _initialCallData) external onlySelf {
        _initialCallTo;
        (uint256[] memory oldTokenIds, , address user) = abi.decode(_initialCallData, (uint256[], IVotingEscrow.LockedBalance[], address));
        emit MigrationFailed(user, oldTokenIds);
    }

    /// @notice function to execute migration on destination chain
    /// @param data encoded data of tokenIds, lockBalances and user address
    function executeMigration(bytes calldata data) internal {
        (uint256[] memory oldTokenIds, MigrationLock[] memory migrationLocks, address user) = abi.decode(data[4:], (uint256[], MigrationLock[], address));
        uint256[] memory newTokenIds = new uint256[](oldTokenIds.length);
        for (uint256 i = 0; i < migrationLocks.length; i++) {
            uint256 amount = migrationLocks[i].amount;
            IERC20(ibToken).mint(address(this), amount);
            IERC20(ibToken).approve(veIB, amount);
            uint256 tokenId = IVotingEscrow(veIB).create_lock_for(amount, migrationLocks[i].duration, user);
            newTokenIds[i] = tokenId;
        }
        emit MigrationCompleted(user, oldTokenIds, newTokenIds);
    }
}
