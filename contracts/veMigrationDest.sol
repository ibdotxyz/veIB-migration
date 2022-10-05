// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IAnyCall.sol";
import "./interfaces/IExecutor.sol";
import "./interfaces/IERC20.sol";

struct MigrationLock {
    uint256 amount;
    uint256 duration;
}

contract veMigrationDest is Ownable, ReentrancyGuard {
    address public immutable ibToken;
    address public immutable anycallExecutor;
    address public immutable anyCall;
    address public immutable veIB;
    uint256 public immutable srcChainId;
    address public sender;

    /// @notice emitted when migration is successful on destination chain
    /// @param user user address
    /// @param oldTokenIds old tokenIds of the user
    /// @param newTokenIds new tokenIds of the user after migration
    event MigrationCompleted(address user, uint256[] oldTokenIds, uint256[] newTokenIds);

    modifier onlyExecutor() {
        require(msg.sender == anycallExecutor, "Only executor can call this function");
        _;
    }

    /// @notice Contract constructor, can be deployed on both the source chain and the destination chainz
    /// @param _ibToken ibToken address
    /// @param _anyCall anyCall address
    /// @param _veIB veIB address
    constructor(
        address _ibToken,
        address _anyCall,
        address _veIB,
        uint256 _srcChainId
    ) {
        require(_ibToken != address(0), "ibToken address cannot be 0");
        require(_anyCall != address(0), "anyCall address cannot be 0");
        require(_veIB != address(0), "veIB address cannot be 0");

        ibToken = _ibToken;
        anyCall = _anyCall;
        anycallExecutor = IAnyCall(_anyCall).executor();
        veIB = _veIB;
        srcChainId = _srcChainId;
    }

    function setup(address _sender) external onlyOwner {
        require(_sender != address(0), "_sender address cannot be 0");
        sender = _sender;
    }

    /// @notice function only callable by anyCall executor, it will be called on destination chain and the source chain
    ///         upon a successful call on the dest chain, it will execute the normal migration flow
    ///         if such call fails, it will in turn call the anyCall executor to initiate a call on the source chain
    ///         with the function selector as anyFallback, which will then log the failure on the source chain
    /// @param data abi encoded data of the anyCall
    /// @return success true if migration is successful
    /// @return result return message
    function anyExecute(bytes calldata data) external onlyExecutor nonReentrant returns (bool success, bytes memory result) {
        (address callFrom, uint256 fromChainID, ) = IExecutor(anycallExecutor).context();
        bool isValidSource = callFrom == sender && fromChainID == srcChainId;
        if (!isValidSource) {
            return (false, "invalid source");
        }
        executeMigration(data);
        return (true, "");
    }

    /// @notice function to execute migration on destination chain
    /// @param data encoded data of tokenIds, lockBalances and user address
    function executeMigration(bytes calldata data) internal {
        (address user, uint256[] memory oldTokenIds, MigrationLock[] memory migrationLocks) = abi.decode(data, (address, uint256[], MigrationLock[]));
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
