// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { MockPriceFeed } from "test/mocks/MockPriceFeed.sol";

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";

contract getAccountEquityUsd_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
    }

    function testFuzz_getAccountEquityUsdOneCollateral(uint256 amountToDeposit) external {
        amountToDeposit = bound({
            x: amountToDeposit,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });
        deal({ token: address(usdc), to: users.naruto.account, give: amountToDeposit });

        uint256 expectedMarginCollateralValue = getPrice(
            MockPriceFeed(marginCollaterals[USDC_MARGIN_COLLATERAL_ID].priceFeed)
        ).mul(convertTokenAmountToUd60x18(address(usdc), amountToDeposit)).intoUint256();

        uint128 tradingAccountId = createAccountAndDeposit(amountToDeposit, address(usdc));

        uint256 marginCollateralValue =
            perpsEngine.getAccountEquityUsd({ tradingAccountId: tradingAccountId }).intoUint256();

        assertEq(marginCollateralValue, expectedMarginCollateralValue, "getAccountEquityUsd");
    }

    function testFuzz_getAccountEquityUsdMultipleCollateral(
        uint256 amountToDepositUsdc,
        uint256 amountToDepositWstEth
    )
        external
    {
        amountToDepositUsdc = bound({
            x: amountToDepositUsdc,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });
        amountToDepositWstEth = bound({
            x: amountToDepositWstEth,
            min: WSTETH_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(wstEth), WSTETH_DEPOSIT_CAP_X18)
        });

        deal({ token: address(usdc), to: users.naruto.account, give: amountToDepositUsdc });
        deal({ token: address(wstEth), to: users.naruto.account, give: amountToDepositWstEth });

        UD60x18 usdcEquityUsd = getPrice(MockPriceFeed(marginCollaterals[USDC_MARGIN_COLLATERAL_ID].priceFeed)).mul(
            convertTokenAmountToUd60x18(address(usdc), amountToDepositUsdc)
        );

        UD60x18 wstEthEquityUsd = getPrice(MockPriceFeed(marginCollaterals[WSTETH_MARGIN_COLLATERAL_ID].priceFeed))
            .mul(convertTokenAmountToUd60x18(address(wstEth), amountToDepositWstEth));

        uint256 expectedMarginCollateralValue = usdcEquityUsd.add(wstEthEquityUsd).intoUint256();

        uint128 tradingAccountId = createAccountAndDeposit(amountToDepositUsdc, address(usdc));

        perpsEngine.depositMargin(tradingAccountId, address(wstEth), amountToDepositWstEth);

        uint256 marginCollateralValue =
            perpsEngine.getAccountEquityUsd({ tradingAccountId: tradingAccountId }).intoUint256();

        assertEq(marginCollateralValue, expectedMarginCollateralValue, "getAccountEquityUsd");
    }
}
