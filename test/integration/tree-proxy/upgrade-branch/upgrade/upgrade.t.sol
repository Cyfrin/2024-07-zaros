// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { Base_Test } from "test/Base.t.sol";
import { RootProxy } from "@zaros/tree-proxy/RootProxy.sol";
import { getBranchUpgrades } from "script/utils/TreeProxyUtils.sol";
import { IPerpsEngine } from "@zaros/perpetuals/PerpsEngine.sol";
import { OrderBranch } from "@zaros/perpetuals/branches/OrderBranch.sol";
import { PerpsEngine } from "@zaros/perpetuals/PerpsEngine.sol";
import { Branch } from "@zaros/tree-proxy/leaves/Branch.sol";

// Open Zeppelin dependencies
import { Ownable } from "@openzeppelin/access/Ownable.sol";

contract TestContract {
    function testFunction() public pure returns (string memory) {
        return "Test";
    }
}

abstract contract PerpsEngineWithNewTestFunction is IPerpsEngine, TestContract { }

contract NewOrderBranch is OrderBranch {
    function getName(uint128 marketId) external pure returns (string memory) {
        marketId++;
        return "Test";
    }
}

abstract contract PerpsEngineWithNewOrderBranch is NewOrderBranch { }

contract Upgrade_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function test_RevertGiven_TheSenderIsNotTheOwner() external {
        changePrank({ msgSender: users.naruto.account });

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.naruto.account)
        });

        perpsEngine.upgrade(new RootProxy.BranchUpgrade[](0), new address[](0), new bytes[](0));
    }

    modifier givenTheSenderIsTheOwner() {
        _;
    }

    function test_WhenAddingANewBranch() external givenTheSenderIsTheOwner {
        changePrank({ msgSender: users.owner.account });

        address[] memory branches = new address[](1);
        address testContract = address(new TestContract());
        branches[0] = testContract;

        bytes4[][] memory branchesSelectors = new bytes4[][](1);
        bytes4[] memory testContractSelectors = new bytes4[](1);
        testContractSelectors[0] = TestContract.testFunction.selector;
        branchesSelectors[0] = testContractSelectors;

        RootProxy.BranchUpgrade[] memory branchUpgrades =
            getBranchUpgrades(branches, branchesSelectors, RootProxy.BranchUpgradeAction.Add);

        perpsEngine.upgrade(branchUpgrades, new address[](0), new bytes[](0));

        // it should return the new branch functions
        assertEq(PerpsEngineWithNewTestFunction(address(perpsEngine)).testFunction(), "Test");
    }

    function test_WhenReplacingABranch() external givenTheSenderIsTheOwner {
        changePrank({ msgSender: users.owner.account });

        address[] memory branches = new address[](1);
        address newOrderBranch = address(new NewOrderBranch());
        branches[0] = newOrderBranch;

        bytes4[][] memory branchesSelectors = new bytes4[][](1);
        bytes4[] memory newOrderBranchSelectors = new bytes4[](1);
        newOrderBranchSelectors[0] = NewOrderBranch.getName.selector;
        branchesSelectors[0] = newOrderBranchSelectors;

        RootProxy.BranchUpgrade[] memory branchUpgrades =
            getBranchUpgrades(branches, branchesSelectors, RootProxy.BranchUpgradeAction.Replace);

        perpsEngine.upgrade(branchUpgrades, new address[](0), new bytes[](0));

        uint128 tradingAcount = 1;

        // it should return the replaced branch functions
        assertEq(PerpsEngineWithNewOrderBranch(address(perpsEngine)).getName(tradingAcount), "Test");
    }

    function test_WhenRemovingABranch() external givenTheSenderIsTheOwner {
        changePrank({ msgSender: users.owner.account });

        // When we remove a function that already exists in the branch

        Branch.Data[] memory perpsEngineBranches = perpsEngine.branches();

        address orderBranchAddress;

        for (uint256 i; i < perpsEngineBranches.length; i++) {
            if (i == 4) {
                orderBranchAddress = perpsEngineBranches[i].branch;
            }
        }

        address[] memory branches = new address[](1);
        branches[0] = orderBranchAddress;

        bytes4[][] memory branchesSelectors = new bytes4[][](1);
        bytes4[] memory orderBranchSelectors = new bytes4[](1);
        orderBranchSelectors[0] = OrderBranch.getActiveMarketOrder.selector;
        branchesSelectors[0] = orderBranchSelectors;

        RootProxy.BranchUpgrade[] memory branchUpgrades =
            getBranchUpgrades(branches, branchesSelectors, RootProxy.BranchUpgradeAction.Remove);

        perpsEngine.upgrade(branchUpgrades, new address[](0), new bytes[](0));

        // it should not return the removed branch functions
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.UnsupportedFunction.selector, OrderBranch.getActiveMarketOrder.selector
            )
        });
        perpsEngine.getActiveMarketOrder(1);

        // When we add a new branch and after delete a function from it

        branches = new address[](1);
        address testContract = address(new TestContract());
        branches[0] = testContract;

        branchesSelectors = new bytes4[][](1);
        bytes4[] memory testContractSelectors = new bytes4[](1);
        testContractSelectors[0] = TestContract.testFunction.selector;
        branchesSelectors[0] = testContractSelectors;

        branchUpgrades = getBranchUpgrades(branches, branchesSelectors, RootProxy.BranchUpgradeAction.Add);

        perpsEngine.upgrade(branchUpgrades, new address[](0), new bytes[](0));
        assertEq(PerpsEngineWithNewTestFunction(address(perpsEngine)).testFunction(), "Test");

        RootProxy.BranchUpgrade[] memory newBranchUpgrades =
            getBranchUpgrades(branches, branchesSelectors, RootProxy.BranchUpgradeAction.Remove);

        perpsEngine.upgrade(newBranchUpgrades, new address[](0), new bytes[](0));

        // it should not return the removed branch functions
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.UnsupportedFunction.selector, TestContract.testFunction.selector)
        });
        PerpsEngineWithNewTestFunction(address(perpsEngine)).testFunction();
    }
}
