// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { RootProxy } from "@zaros/tree-proxy/RootProxy.sol";
import { getBranchUpgrades } from "script/utils/TreeProxyUtils.sol";
import { IPerpsEngine } from "@zaros/perpetuals/PerpsEngine.sol";
import { PerpsEngine } from "@zaros/perpetuals/PerpsEngine.sol";
import { Branch } from "@zaros/tree-proxy/leaves/Branch.sol";
import { LookupBranch } from "@zaros/tree-proxy/branches/LookupBranch.sol";

// Open Zeppelin dependencies
import { Ownable } from "@openzeppelin/access/Ownable.sol";

contract TestContract is RootProxy {
    constructor(InitParams memory initParams) RootProxy(initParams) { }

    function testFunction() public pure returns (string memory) {
        return "Test";
    }

    receive() external payable { }
}

contract RootProxy_Integration_Test is Base_Test {
    function test_WhenInitializeContract() external {
        // Deploy test contract
        TestContract testContract;
        address[] memory branches = new address[](1);
        bytes4[][] memory selectors = new bytes4[][](1);

        address lookupBranch = address(new LookupBranch());

        branches[0] = lookupBranch;

        bytes4[] memory lookupBranchSelectors = new bytes4[](4);

        lookupBranchSelectors[0] = LookupBranch.branches.selector;
        lookupBranchSelectors[1] = LookupBranch.branchFunctionSelectors.selector;
        lookupBranchSelectors[2] = LookupBranch.branchAddresses.selector;
        lookupBranchSelectors[3] = LookupBranch.branchAddress.selector;

        selectors[0] = lookupBranchSelectors;

        RootProxy.BranchUpgrade[] memory branchUpgrades =
            getBranchUpgrades(branches, selectors, RootProxy.BranchUpgradeAction.Add);

        RootProxy.InitParams memory initParams = RootProxy.InitParams({
            initBranches: branchUpgrades,
            initializables: new address[](0),
            initializePayloads: new bytes[](0)
        });
        testContract = (new TestContract(initParams));

        // it should return the new contract
        assertEq(testContract.testFunction(), "Test");
        Branch.Data[] memory contractBranches = IPerpsEngine(address(testContract)).branches();
        assertEq(contractBranches.length, 1, "Invalid branches length");
    }
}
