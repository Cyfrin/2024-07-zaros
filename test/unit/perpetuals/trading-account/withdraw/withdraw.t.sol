// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";

// PRB Math dependencies
import { UD60x18 } from "@prb-math/UD60x18.sol";

contract Withdraw_Unit_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function testFuzz_WhenTheNewMarginCollateralBalanceIsZero(uint256 amountToDeposit) external {
        // Test with wstEth that has 18 decimals

        amountToDeposit = bound({
            x: amountToDeposit,
            min: WSTETH_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(wstEth), WSTETH_DEPOSIT_CAP_X18)
        });

        uint256 amountToWithdraw = amountToDeposit;

        UD60x18 amountToDepositX18 = convertTokenAmountToUd60x18(address(wstEth), amountToDeposit);
        UD60x18 amountToWithdrawX18 = convertTokenAmountToUd60x18(address(wstEth), amountToWithdraw);

        deal({ token: address(wstEth), to: users.naruto.account, give: amountToDeposit });

        uint128 tradingAccountId = createAccountAndDeposit(amountToDeposit, address(wstEth));

        perpsEngine.exposed_withdraw(tradingAccountId, address(wstEth), amountToWithdrawX18);

        bool marginCollateralBalanceX18ContainsTheCollateral = perpsEngine
            .workaround_getIfMarginCollateralBalanceX18ContainsTheCollateral(tradingAccountId, address(wstEth));

        uint256 actualTotalDeposited = perpsEngine.workaround_getTotalDeposited(address(wstEth));
        uint256 expectedTotalDeposited = 0;

        // it should update the total deposited
        assertEq(expectedTotalDeposited, actualTotalDeposited, "total deposited is not correct");

        // it should remove the collateral
        assertEq(marginCollateralBalanceX18ContainsTheCollateral, false, "the collateral should be removed");

        // Test with usdc that has 6 decimals

        amountToDeposit = bound({
            x: amountToDeposit,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });

        amountToWithdraw = amountToDeposit;

        amountToDepositX18 = convertTokenAmountToUd60x18(address(usdc), amountToDeposit);
        amountToWithdrawX18 = convertTokenAmountToUd60x18(address(usdc), amountToWithdraw);

        deal({ token: address(usdc), to: users.naruto.account, give: amountToDeposit });

        perpsEngine.depositMargin(tradingAccountId, address(usdc), amountToDeposit);

        perpsEngine.exposed_withdraw(tradingAccountId, address(usdc), amountToWithdrawX18);

        marginCollateralBalanceX18ContainsTheCollateral = perpsEngine
            .workaround_getIfMarginCollateralBalanceX18ContainsTheCollateral(tradingAccountId, address(usdc));

        actualTotalDeposited = perpsEngine.workaround_getTotalDeposited(address(wstEth));
        expectedTotalDeposited = 0;

        // it should update the total deposited
        assertEq(expectedTotalDeposited, actualTotalDeposited, "total deposited is not correct");

        // it should remove the collateral
        assertEq(marginCollateralBalanceX18ContainsTheCollateral, false, "the collateral should be removed");
    }

    function testFuzz_WhenTheNewMarginCollateralBalanceIsNotZero(
        uint256 amountToDeposit,
        uint256 amountToWithdraw
    )
        external
    {
        // Test with wstEth that has 18 decimals

        amountToDeposit = bound({
            x: amountToDeposit,
            min: WSTETH_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(wstEth), WSTETH_DEPOSIT_CAP_X18)
        });

        vm.assume(amountToWithdraw > 0 && amountToDeposit > amountToWithdraw);

        UD60x18 amountToDepositX18 = convertTokenAmountToUd60x18(address(wstEth), amountToDeposit);
        UD60x18 amountToWithdrawX18 = convertTokenAmountToUd60x18(address(wstEth), amountToWithdraw);

        deal({ token: address(wstEth), to: users.naruto.account, give: amountToDeposit });

        uint128 tradingAccountId = createAccountAndDeposit(amountToDeposit, address(wstEth));

        perpsEngine.exposed_withdraw(tradingAccountId, address(wstEth), amountToWithdrawX18);

        uint256 receivedMarginCollateralBalance =
            perpsEngine.exposed_getMarginCollateralBalance(tradingAccountId, address(wstEth)).intoUint256();

        uint256 actualTotalDeposited = perpsEngine.workaround_getTotalDeposited(address(wstEth));
        uint256 expectedTotalDeposited = (amountToDepositX18.sub(amountToWithdrawX18)).intoUint256();

        // it should update the total deposited
        assertEq(expectedTotalDeposited, actualTotalDeposited, "total deposited is not correct");

        // it should update the new balance
        assertEq(
            actualTotalDeposited, receivedMarginCollateralBalance, "the margin collateral balance should be updated"
        );

        // Test with usdc that has 6 decimals

        amountToDeposit = bound({
            x: amountToDeposit,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });

        vm.assume(amountToWithdraw > 0 && amountToDeposit > amountToWithdraw);

        amountToDepositX18 = convertTokenAmountToUd60x18(address(usdc), amountToDeposit);
        amountToWithdrawX18 = convertTokenAmountToUd60x18(address(usdc), amountToWithdraw);

        deal({ token: address(usdc), to: users.naruto.account, give: amountToDeposit });

        perpsEngine.depositMargin(tradingAccountId, address(usdc), amountToDeposit);

        perpsEngine.exposed_withdraw(tradingAccountId, address(usdc), amountToWithdrawX18);

        receivedMarginCollateralBalance =
            perpsEngine.exposed_getMarginCollateralBalance(tradingAccountId, address(usdc)).intoUint256();
        actualTotalDeposited = (amountToDepositX18.sub(amountToWithdrawX18)).intoUint256();

        actualTotalDeposited = perpsEngine.workaround_getTotalDeposited(address(usdc));
        expectedTotalDeposited = (amountToDepositX18.sub(amountToWithdrawX18)).intoUint256();

        // it should update the total deposited
        assertEq(expectedTotalDeposited, actualTotalDeposited, "total deposited is not correct");

        // it should update the new balance
        assertEq(
            actualTotalDeposited, receivedMarginCollateralBalance, "the margin collateral balance should be updated"
        );
    }
}
