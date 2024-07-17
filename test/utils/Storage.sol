// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

abstract contract Storage {
    /// @dev GlobalConfiguration namespace storage location.
    bytes32 internal constant GLOBAL_CONFIGURATION_LOCATION = keccak256(
        abi.encode(uint256(keccak256("fi.zaros.perpetuals.GlobalConfiguration")) - 1)
    ) & ~bytes32(uint256(0xff));
}
