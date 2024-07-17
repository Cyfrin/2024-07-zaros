// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Forge dependencies
import { Script } from "forge-std/Script.sol";

abstract contract BaseScript is Script {
    /// @dev Included to enable compilation of the script without a $PRIVATE_KEY environment variable.
    uint256 internal constant TEST_PRIVATE_KEY = 1;

    /// @dev Needed for the deterministic deployments.
    bytes32 internal constant ZERO_SALT = bytes32(0);

    /// @dev The address of the contract deployer.
    address internal deployer;

    /// @dev Used to derive the deployer's address.
    uint256 internal privateKey;

    constructor() {
        privateKey = vm.envOr("PRIVATE_KEY", TEST_PRIVATE_KEY);
        deployer = vm.rememberKey(privateKey);
    }

    modifier broadcaster() {
        vm.startBroadcast(deployer);
        _;
        vm.stopBroadcast();
    }
}
