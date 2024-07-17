// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { RootUpgrade } from "./leaves/RootUpgrade.sol";

// Open Zeppelin dependencies
import { Proxy } from "@openzeppelin/proxy/Proxy.sol";

/**
 * @title RootProxy
 * @notice Interface of the RootProxy Proxy contract.
 */
abstract contract RootProxy is Proxy {
    using RootUpgrade for RootUpgrade.Data;

    /// @notice Branch upgrade action types.
    enum BranchUpgradeAction {
        Add,
        Replace,
        Remove
    }

    /// @notice Init params of the RootProxy contract.
    struct InitParams {
        BranchUpgrade[] initBranches;
        address[] initializables;
        bytes[] initializePayloads;
    }

    /// @notice Describes a branch to be added, replaced or removed.
    /// @param branch Address of the branch, that contains the functions.
    /// @param action The action to be performed.
    /// @param selectors The function selectors of the branch to be cut.
    struct BranchUpgrade {
        address branch;
        BranchUpgradeAction action;
        bytes4[] selectors;
    }

    constructor(InitParams memory initRootUpgrade) {
        RootUpgrade.Data storage rootUpgrade = RootUpgrade.load();

        rootUpgrade.upgrade(
            initRootUpgrade.initBranches, initRootUpgrade.initializables, initRootUpgrade.initializePayloads
        );
    }

    function _implementation() internal view override returns (address branch) {
        RootUpgrade.Data storage rootUpgrade = RootUpgrade.load();

        branch = rootUpgrade.getBranchAddress(msg.sig);
        if (branch == address(0)) revert Errors.UnsupportedFunction(msg.sig);
    }
}
