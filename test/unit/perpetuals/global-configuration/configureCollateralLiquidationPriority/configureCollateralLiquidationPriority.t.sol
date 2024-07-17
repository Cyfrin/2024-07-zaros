// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { Base_Test } from "test/Base.t.sol";

contract ConfigureCollateralLiquidationPriority_Unit_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function test_RevertWhen_TheCollateralAddressIsZero() external {
        address collateral = address(0);
        address[] memory collateralTypes = new address[](1);

        collateralTypes[0] = collateral;

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "collateralType") });

        perpsEngine.exposed_configureCollateralLiquidationPriority(collateralTypes);
    }

    function test_RevertWhen_TheCollateralIsAlreadyAddedInTheLiquidationPriority() external {
        address collateralType = address(123);
        address[] memory collateralTypes = new address[](2);

        collateralTypes[0] = collateralType;
        collateralTypes[1] = collateralType;

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.MarginCollateralAlreadyInPriority.selector, collateralType)
        });

        perpsEngine.exposed_configureCollateralLiquidationPriority(collateralTypes);
    }

    function test_WhenTheCollateralWasNotAddedInTheLiquidationPriority() external {
        address collateralType1 = address(123);
        address collateralType2 = address(456);
        address[] memory collateralTypes = new address[](2);

        collateralTypes[0] = collateralType1;
        collateralTypes[1] = collateralType2;

        uint256 oldLength = perpsEngine.workaround_getCollateralLiquidationPriority().length;

        // it should add the collateral in the liquidation priority
        perpsEngine.exposed_configureCollateralLiquidationPriority(collateralTypes);

        address[] memory arrayOfCollaterals = perpsEngine.workaround_getCollateralLiquidationPriority();

        uint256 newLength = arrayOfCollaterals.length;

        assertEq(newLength - oldLength, 2, "the length should be increased by 2");
        assertEq(arrayOfCollaterals[newLength - 2], collateralType1, "the first collateral should be added");
        assertEq(arrayOfCollaterals[newLength - 1], collateralType2, "the second collateral should be added");
    }
}
