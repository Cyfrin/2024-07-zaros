// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { RootProxy } from "@zaros/tree-proxy/RootProxy.sol";
import { RootUpgrade } from "@zaros/tree-proxy/leaves/RootUpgrade.sol";
import { Branch } from "@zaros/tree-proxy/leaves/Branch.sol";

// Open Zeppelin dependencies
import { Address } from "@openzeppelin/utils/Address.sol";
import { EnumerableSet } from "@openzeppelin/utils/structs/EnumerableSet.sol";

library RootUpgrade {
    using EnumerableSet for *;

    /// @notice ERC7201 storage location.
    bytes32 internal constant ROOT_UPGRADE_LOCATION =
        keccak256(abi.encode(uint256(keccak256("fi.zaros.perpetuals.RootUpgrade")) - 1)) & ~bytes32(uint256(0xff));

    struct Data {
        EnumerableSet.AddressSet branches;
        mapping(bytes4 selector => address branch) selectorToBranch;
        mapping(address branch => EnumerableSet.Bytes32Set selectors) branchSelectors;
    }

    function load() internal pure returns (Data storage rootUpgrade) {
        bytes32 position = ROOT_UPGRADE_LOCATION;

        assembly {
            rootUpgrade.slot := position
        }
    }

    function validateBranchUpgrade(RootProxy.BranchUpgrade memory branchUpgrade) internal view {
        if (uint256(branchUpgrade.action) > 2) {
            revert Errors.IncorrectBranchUpgradeAction();
        }
        if (branchUpgrade.branch == address(0)) {
            revert Errors.BranchIsZeroAddress();
        }
        if (branchUpgrade.branch.code.length == 0) {
            revert Errors.BranchIsNotContract(branchUpgrade.branch);
        }
        if (branchUpgrade.selectors.length == 0) {
            revert Errors.SelectorArrayEmpty(branchUpgrade.branch);
        }
    }

    function getBranchAddress(Data storage self, bytes4 functionSelector) internal view returns (address branch) {
        branch = self.selectorToBranch[functionSelector];
    }

    function getBranchAddresses(Data storage self) internal view returns (address[] memory branchAddresses) {
        branchAddresses = self.branches.values();
    }

    function getBranchSelectors(
        Data storage self,
        address branch
    )
        internal
        view
        returns (bytes4[] memory selectors)
    {
        EnumerableSet.Bytes32Set storage branchSelectors_ = self.branchSelectors[branch];
        uint256 selectorCount = branchSelectors_.length();
        selectors = new bytes4[](selectorCount);
        for (uint256 i; i < selectorCount; i++) {
            selectors[i] = bytes4(branchSelectors_.at(i));
        }
    }

    function getBranches(Data storage self) internal view returns (Branch.Data[] memory branches) {
        address[] memory branchAddresses = getBranchAddresses(self);
        uint256 branchCount = branchAddresses.length;
        branches = new Branch.Data[](branchCount);

        // Build up branch struct.
        for (uint256 i; i < branchCount; i++) {
            address branch = branchAddresses[i];
            bytes4[] memory selectors = getBranchSelectors(self, branch);

            branches[i] = Branch.Data({ branch: branch, selectors: selectors });
        }
    }

    function upgrade(
        Data storage self,
        RootProxy.BranchUpgrade[] memory branchUpgrades,
        address[] memory initializables,
        bytes[] memory initializePayloads
    )
        internal
    {
        uint256 cachedBranchUpgradesLength = branchUpgrades.length;

        for (uint256 i; i < cachedBranchUpgradesLength; i++) {
            RootProxy.BranchUpgrade memory branchUpgrade = branchUpgrades[i];

            validateBranchUpgrade(branchUpgrade);

            if (branchUpgrade.action == RootProxy.BranchUpgradeAction.Add) {
                addBranch(self, branchUpgrade.branch, branchUpgrade.selectors);
            } else if (branchUpgrade.action == RootProxy.BranchUpgradeAction.Replace) {
                replaceBranch(self, branchUpgrade.branch, branchUpgrade.selectors);
            } else if (branchUpgrade.action == RootProxy.BranchUpgradeAction.Remove) {
                removeBranch(self, branchUpgrade.branch, branchUpgrade.selectors);
            }
        }

        initializeRootUpgrade(branchUpgrades, initializables, initializePayloads);
    }

    function addBranch(Data storage self, address branch, bytes4[] memory selectors) internal {
        // slither-disable-next-line unused-return
        self.branches.add(branch);

        uint256 cachedSelectorsLength = selectors.length;

        for (uint256 i; i < cachedSelectorsLength; i++) {
            bytes4 selector = selectors[i];

            if (selector == bytes4(0)) {
                revert Errors.SelectorIsZero();
            }
            if (self.selectorToBranch[selector] != address(0)) {
                revert Errors.FunctionAlreadyExists(selector);
            }

            self.selectorToBranch[selector] = branch;
            // slither-disable-next-line unused-return
            self.branchSelectors[branch].add(selector);
        }
    }

    function replaceBranch(Data storage self, address branch, bytes4[] memory selectors) internal {
        // slither-disable-next-line unused-return
        self.branches.add(branch);

        uint256 cachedSelectorsLength = selectors.length;

        for (uint256 i; i < cachedSelectorsLength; i++) {
            bytes4 selector = selectors[i];
            address oldBranch = self.selectorToBranch[selector];

            if (selector == bytes4(0)) {
                revert Errors.SelectorIsZero();
            }
            if (oldBranch == address(this)) {
                revert Errors.ImmutableBranch();
            }
            if (oldBranch == branch) {
                revert Errors.FunctionFromSameBranch(selector);
            }
            if (oldBranch == address(0)) {
                revert Errors.NonExistingFunction(selector);
            }

            // overwrite selector to new branch
            self.selectorToBranch[selector] = branch;

            // slither-disable-next-line unused-return
            self.branchSelectors[branch].add(selector);

            // slither-disable-next-line unused-return
            self.branchSelectors[oldBranch].remove(selector);

            // if no more selectors, remove old branch address
            if (self.branchSelectors[oldBranch].length() == 0) {
                // slither-disable-next-line unused-return
                self.branches.remove(oldBranch);
            }
        }
    }

    function removeBranch(Data storage self, address branch, bytes4[] memory selectors) internal {
        if (branch == address(this)) {
            revert Errors.ImmutableBranch();
        }

        uint256 cachedSelectorsLength = selectors.length;

        for (uint256 i; i < cachedSelectorsLength; i++) {
            bytes4 selector = selectors[i];
            // also reverts if left side returns zero address
            if (selector == bytes4(0)) {
                revert Errors.SelectorIsZero();
            }
            if (self.selectorToBranch[selector] != branch) {
                revert Errors.CannotRemoveFromOtherBranch(branch, selector);
            }

            delete self.selectorToBranch[selector];
            // slither-disable-next-line unused-return
            self.branchSelectors[branch].remove(selector);
        }

        // if no more selectors in branch, remove branch address
        if (self.branchSelectors[branch].length() == 0) {
            // slither-disable-next-line unused-return
            self.branches.remove(branch);
        }
    }

    function initializeRootUpgrade(
        RootProxy.BranchUpgrade[] memory,
        address[] memory initializables,
        bytes[] memory initializePayloads
    )
        internal
    {
        for (uint256 i; i < initializables.length; i++) {
            address initializable = initializables[i];
            bytes memory data = initializePayloads[i];

            if (initializable.code.length == 0) {
                revert Errors.InitializableIsNotContract(initializable);
            }

            Address.functionDelegateCall(initializable, data);
        }
    }
}
