// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";

// Open Zeppelin dependencies
import { OwnableUpgradeable } from "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";

abstract contract BaseKeeper is UUPSUpgradeable, OwnableUpgradeable {
    /// @notice ERC7201 storage location.
    bytes32 internal constant BASE_KEEPER_LOCATION = keccak256(
        abi.encode(uint256(keccak256("fi.zaros.external.chainlink.keepers.BaseKeeper")) - 1)
    ) & ~bytes32(uint256(0xff));

    /// @notice Chainlink Data Streams Reports default decimals (both Basic and Premium).
    uint8 internal constant REPORT_PRICE_DECIMALS = 8;

    /// @custom:storage-location erc7201:fi.zaros.external.chainlink.BaseKeeper
    /// @param forwarder The address of the Keeper forwarder contract.
    struct BaseKeeperStorage {
        address forwarder;
    }

    /// @notice Ensures that only the Keeper's forwarder contract can call a function.
    modifier onlyForwarder() {
        BaseKeeperStorage storage self = _getBaseKeeperStorage();
        bool isSenderForwarder = msg.sender == self.forwarder;

        if (!isSenderForwarder) {
            revert Errors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @notice Updates the Keeper forwarder address.
    /// @param forwarder The new forwarder address.
    function setForwarder(address forwarder) external onlyOwner {
        BaseKeeperStorage storage self = _getBaseKeeperStorage();
        self.forwarder = forwarder;
    }

    /// @notice {BaseKeeper} UUPS initializer.
    function __BaseKeeper_init(address owner) internal onlyInitializing {
        if (owner == address(0)) {
            revert Errors.ZeroInput("owner");
        }

        __Ownable_init(owner);
    }

    function _getBaseKeeperStorage() internal pure returns (BaseKeeperStorage storage self) {
        bytes32 slot = BASE_KEEPER_LOCATION;

        assembly {
            self.slot := slot
        }
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal override onlyOwner { }
}
