// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";

contract GetAccountMarginCollateralBalance_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
    }

    function testFuzz_GetAccountMarginCollateralBalance(uint256 amountToDeposit) external {
        amountToDeposit = bound({
            x: amountToDeposit,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });
        deal({ token: address(usdc), to: users.naruto.account, give: amountToDeposit });

        uint128 tradingAccountId = createAccountAndDeposit(amountToDeposit, address(usdc));

        uint256 marginCollateralAmount = convertUd60x18ToTokenAmount(
            address(usdc),
            perpsEngine.getAccountMarginCollateralBalance({
                tradingAccountId: tradingAccountId,
                collateralType: address(usdc)
            })
        );
        assertEq(marginCollateralAmount, amountToDeposit, "getAccountMarginCollateralBalance");
    }
}
