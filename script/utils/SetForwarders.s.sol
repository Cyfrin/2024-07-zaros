// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { BaseKeeper } from "@zaros/external/chainlink/keepers/BaseKeeper.sol";
import { BaseScript } from "script/Base.s.sol";

// Forge dependencies
import { console } from "forge-std/console.sol";

contract SetForwarders is BaseScript {
    function run(address[] calldata keepers, address[] calldata forwarders) public broadcaster {
        // solhint-disable-next-line custom-errors
        require(keepers.length == forwarders.length, "invalid input length");

        for (uint256 i; i < keepers.length; i++) {
            address target = keepers[i];
            address forwarder = forwarders[i];

            console.log("Setting forwarder for", target, "to", forwarder);

            // Set the forwarder
            BaseKeeper(target).setForwarder(forwarder);
        }
    }
}
