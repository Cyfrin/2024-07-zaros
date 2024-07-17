// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { Base_Test } from "test/Base.t.sol";

contract RemoveCollateralFromLiquidationPriority_Unit_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function test_RevertWhen_TheCollateralIsAlreadyRemovedInTheLiquidationPriority() external {
        address collateralType1 = address(123);
        address collateralType2 = address(456);
        address[] memory collateralTypes = new address[](2);

        collateralTypes[0] = collateralType1;
        collateralTypes[1] = collateralType2;

        perpsEngine.exposed_configureCollateralLiquidationPriority(collateralTypes);

        perpsEngine.exposed_removeCollateralFromLiquidationPriority(collateralType1);

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.MarginCollateralTypeNotInPriority.selector, collateralType1)
        });

        perpsEngine.exposed_removeCollateralFromLiquidationPriority(collateralType1);
    }

    function testFuzz_WhenTheCollateralWasNotRemovedInTheLiquidationPriority(
        uint256 numberOfCollaterals,
        uint256 indexRemoveCollateral
    )
        external
    {
        numberOfCollaterals = bound({ x: numberOfCollaterals, min: 1, max: 500 });
        indexRemoveCollateral = bound({ x: indexRemoveCollateral, min: 0, max: numberOfCollaterals - 1 });

        address[] memory collateralLiquidationPriority = perpsEngine.workaround_getCollateralLiquidationPriority();
        for (uint256 i = 0; i < collateralLiquidationPriority.length; i++) {
            perpsEngine.exposed_removeCollateralFromLiquidationPriority(collateralLiquidationPriority[i]);
        }

        address[] memory collateralTypes = new address[](numberOfCollaterals);
        for (uint256 i = 0; i < numberOfCollaterals; i++) {
            collateralTypes[i] = address(uint160(i + 1));
        }

        collateralLiquidationPriority = perpsEngine.workaround_getCollateralLiquidationPriority();

        assertEq(collateralLiquidationPriority.length, 0, "collateral liquidation priority should be empty");

        perpsEngine.exposed_configureCollateralLiquidationPriority(collateralTypes);

        collateralLiquidationPriority = perpsEngine.workaround_getCollateralLiquidationPriority();

        assertEq(
            collateralLiquidationPriority.length,
            numberOfCollaterals,
            "collateral should be added to the liquidation priority"
        );
        for (uint256 i = 0; i < numberOfCollaterals; i++) {
            assertEq(collateralLiquidationPriority[i], collateralTypes[i], "collateral should be in the same order");
        }

        perpsEngine.exposed_removeCollateralFromLiquidationPriority(
            collateralLiquidationPriority[indexRemoveCollateral]
        );

        collateralLiquidationPriority = perpsEngine.workaround_getCollateralLiquidationPriority();

        assertEq(
            collateralLiquidationPriority.length,
            numberOfCollaterals - 1,
            "collateral length should be decreased by 1"
        );

        for (uint256 i = 0; i < numberOfCollaterals - 1; i++) {
            address collateral = collateralTypes[i < indexRemoveCollateral ? i : i + 1];

            // it should remove the collateral in the liquidation priority
            assertEq(
                collateral != collateralTypes[indexRemoveCollateral],
                true,
                "collateral should be removed from the liquidation priority"
            );

            // it should keep the same order in the liquidation priority
            assertEq(collateralLiquidationPriority[i], collateral, "collateral should be in the same order");
        }
    }
}
