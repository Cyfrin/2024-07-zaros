// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { RootProxy } from "@zaros/tree-proxy/RootProxy.sol";
import { getBranchUpgrades } from "script/utils/TreeProxyUtils.sol";
import { IPerpsEngine } from "@zaros/perpetuals/PerpsEngine.sol";
import { PerpsEngine } from "@zaros/perpetuals/PerpsEngine.sol";
import { LookupBranch } from "@zaros/tree-proxy/branches/LookupBranch.sol";
import { PerpMarketBranch } from "@zaros/perpetuals/branches/PerpMarketBranch.sol";
import { Branch } from "@zaros/tree-proxy/leaves/Branch.sol";

contract Branches_Integration_Test is Base_Test {
    IPerpsEngine testPerpsEngine;
    address[] branches = new address[](2);
    bytes4[][] selectors = new bytes4[][](2);

    function setUp() public override {
        Base_Test.setUp();

        // Deploy test contract with two branches and selectors

        address lookupBranch = address(new LookupBranch());
        address perpMarketBranch = address(new PerpMarketBranch());

        branches[0] = lookupBranch;
        branches[1] = perpMarketBranch;

        bytes4[] memory lookupBranchSelectors = new bytes4[](4);

        lookupBranchSelectors[0] = LookupBranch.branches.selector;
        lookupBranchSelectors[1] = LookupBranch.branchFunctionSelectors.selector;
        lookupBranchSelectors[2] = LookupBranch.branchAddresses.selector;
        lookupBranchSelectors[3] = LookupBranch.branchAddress.selector;

        bytes4[] memory perpMarketBranchSelectors = new bytes4[](2);

        perpMarketBranchSelectors[0] = PerpMarketBranch.getName.selector;
        perpMarketBranchSelectors[1] = PerpMarketBranch.getSymbol.selector;

        selectors[0] = lookupBranchSelectors;
        selectors[1] = perpMarketBranchSelectors;

        RootProxy.BranchUpgrade[] memory branchUpgrades =
            getBranchUpgrades(branches, selectors, RootProxy.BranchUpgradeAction.Add);

        RootProxy.InitParams memory initParams = RootProxy.InitParams({
            initBranches: branchUpgrades,
            initializables: new address[](0),
            initializePayloads: new bytes[](0)
        });

        testPerpsEngine = IPerpsEngine(address(new PerpsEngine(initParams)));

        changePrank({ msgSender: users.naruto.account });
    }

    function test_WhenBranchesIsCalled() external {
        Branch.Data[] memory testPerpsEngineBranches = testPerpsEngine.branches();

        // it should return the branches
        assertEq(testPerpsEngineBranches.length, branches.length, "Invalid branches length");

        for (uint256 i; i < testPerpsEngineBranches.length; i++) {
            assertEq(testPerpsEngineBranches[i].branch, branches[i], "Invalid branch address");

            // it should return the selectors
            assertEq(testPerpsEngineBranches[i].selectors.length, selectors[i].length, "Invalid selectors length");

            for (uint256 j = 0; j < testPerpsEngineBranches[i].selectors.length; j++) {
                assertEq(testPerpsEngineBranches[i].selectors[j], selectors[i][j], "Invalid selector");
            }
        }
    }
}
