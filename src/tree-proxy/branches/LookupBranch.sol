// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { RootUpgrade } from "../leaves/RootUpgrade.sol";
import { LookupTable } from "../leaves/LookupTable.sol";
import { Branch } from "../leaves/Branch.sol";

// Open Zeppelin dependencies
import { EnumerableSet } from "@openzeppelin/utils/structs/EnumerableSet.sol";

contract LookupBranch {
    using RootUpgrade for RootUpgrade.Data;
    using LookupTable for LookupTable.Data;
    using EnumerableSet for *;

    function branches() external view returns (Branch.Data[] memory) {
        RootUpgrade.Data storage rootUpgrade = RootUpgrade.load();

        return rootUpgrade.getBranches();
    }

    function branchFunctionSelectors(address branch) external view returns (bytes4[] memory) {
        RootUpgrade.Data storage rootUpgrade = RootUpgrade.load();

        return rootUpgrade.getBranchSelectors(branch);
    }

    function branchAddresses() external view returns (address[] memory) {
        RootUpgrade.Data storage rootUpgrade = RootUpgrade.load();

        return rootUpgrade.getBranchAddresses();
    }

    function branchAddress(bytes4 selector) external view returns (address) {
        RootUpgrade.Data storage rootUpgrade = RootUpgrade.load();

        return rootUpgrade.getBranchAddress(selector);
    }
}
