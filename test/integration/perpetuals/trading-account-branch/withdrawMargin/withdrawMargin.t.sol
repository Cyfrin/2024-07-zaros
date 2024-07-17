// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { Errors } from "@zaros/utils/Errors.sol";
import { OrderBranch } from "@zaros/perpetuals/branches/OrderBranch.sol";
import { TradingAccountBranch } from "@zaros/perpetuals/branches/TradingAccountBranch.sol";
import { SettlementConfiguration } from "@zaros/perpetuals/leaves/SettlementConfiguration.sol";

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";
import { SD59x18 } from "@prb-math/SD59x18.sol";

contract WithdrawMargin_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();

        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function testFuzz_RevertGiven_TheAccountDoesNotExist(uint128 tradingAccountId) external {
        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.AccountNotFound.selector, tradingAccountId, users.naruto.account)
        });
        perpsEngine.withdrawMargin(tradingAccountId, address(usdc), 0);
    }

    modifier givenTheAccountExists() {
        _;
    }

    function test_RevertGiven_TheSenderIsNotAuthorized() external givenTheAccountExists {
        // it should revert
    }

    function testFuzz_RevertGiven_TheSenderIsNotAuthorized(
        uint256 amountToDeposit,
        uint256 amountToWithdraw
    )
        external
        givenTheAccountExists
    {
        amountToDeposit = bound({
            x: amountToDeposit,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });
        amountToWithdraw = bound({ x: amountToWithdraw, min: USDC_MIN_DEPOSIT_MARGIN, max: amountToDeposit });
        deal({ token: address(usdc), to: users.naruto.account, give: amountToDeposit });

        uint128 tradingAccountId = createAccountAndDeposit(amountToDeposit, address(usdc));
        changePrank({ msgSender: users.sasuke.account });

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.AccountPermissionDenied.selector, tradingAccountId, users.sasuke.account
            )
        });
        perpsEngine.withdrawMargin(tradingAccountId, address(usdc), amountToWithdraw);
    }

    modifier givenTheSenderIsAuthorized() {
        _;
    }

    function testFuzz_RevertWhen_TheAmountIsZero(uint256 amountToDeposit)
        external
        givenTheAccountExists
        givenTheSenderIsAuthorized
    {
        amountToDeposit = bound({
            x: amountToDeposit,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });
        deal({ token: address(usdc), to: users.naruto.account, give: amountToDeposit });

        uint128 tradingAccountId = createAccountAndDeposit(amountToDeposit, address(usdc));

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "amount") });
        perpsEngine.withdrawMargin(tradingAccountId, address(usdc), 0);
    }

    modifier whenTheAmountIsNotZero() {
        _;
    }

    function testFuzz_RevertGiven_ThereIsntEnoughMarginCollateral(
        uint256 amountToDeposit,
        uint256 amountToWithdraw
    )
        external
        givenTheAccountExists
        givenTheSenderIsAuthorized
        whenTheAmountIsNotZero
    {
        amountToDeposit = bound({
            x: amountToDeposit,
            min: WSTETH_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(wstEth), WSTETH_DEPOSIT_CAP_X18)
        });
        vm.assume(amountToWithdraw > amountToDeposit);
        uint256 expectedMarginCollateralBalance =
            convertTokenAmountToUd60x18(address(wstEth), amountToDeposit).intoUint256();
        deal({ token: address(wstEth), to: users.naruto.account, give: amountToDeposit });

        uint128 tradingAccountId = createAccountAndDeposit(amountToDeposit, address(wstEth));

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.InsufficientCollateralBalance.selector, amountToWithdraw, expectedMarginCollateralBalance
            )
        });
        perpsEngine.withdrawMargin(tradingAccountId, address(wstEth), amountToWithdraw);
    }

    modifier givenThereIsEnoughMarginCollateral() {
        _;
    }

    struct TestFuzz_RevertGiven_TheAccountWontMeetTheMarginRequirement_Context {
        MarketConfig fuzzMarketConfig;
        UD60x18 adjustedMarginRequirements;
        UD60x18 maxMarginValueUsd;
        uint256 amountToWithdraw;
        uint128 tradingAccountId;
        int128 sizeDelta;
        SD59x18 marginBalanceUsdX18;
        UD60x18 requiredInitialMarginUsdX18;
        UD60x18 orderFeeUsdX18;
        UD60x18 settlementFeeUsdX18;
        bytes mockSignedReport;
    }

    function testFuzz_RevertGiven_TheAccountWontMeetTheMarginRequirement(
        uint256 marginValueUsd,
        bool isLong,
        uint256 marketId
    )
        external
        givenTheAccountExists
        givenTheSenderIsAuthorized
        whenTheAmountIsNotZero
        givenThereIsEnoughMarginCollateral
    {
        TestFuzz_RevertGiven_TheAccountWontMeetTheMarginRequirement_Context memory ctx;
        ctx.fuzzMarketConfig = getFuzzMarketConfig(marketId);
        ctx.adjustedMarginRequirements = ud60x18(ctx.fuzzMarketConfig.imr).mul(ud60x18(1.001e18));

        // avoids very small rounding errors in super edge cases
        // ctx.adjustedMarginRequirements = ud60x18(ctx.fuzzMarketConfig.imr).mul(ud60x18(1.001e18));
        ctx.maxMarginValueUsd = ctx.adjustedMarginRequirements.mul(ud60x18(ctx.fuzzMarketConfig.maxSkew)).mul(
            ud60x18(ctx.fuzzMarketConfig.mockUsdPrice)
        );

        marginValueUsd =
            bound({ x: marginValueUsd, min: USDZ_MIN_DEPOSIT_MARGIN, max: ctx.maxMarginValueUsd.intoUint256() });
        ctx.amountToWithdraw = marginValueUsd;

        deal({ token: address(usdz), to: users.naruto.account, give: marginValueUsd });

        ctx.tradingAccountId = createAccountAndDeposit(marginValueUsd, address(usdz));
        int128 sizeDelta = fuzzOrderSizeDelta(
            FuzzOrderSizeDeltaParams({
                tradingAccountId: ctx.tradingAccountId,
                marketId: ctx.fuzzMarketConfig.marketId,
                settlementConfigurationId: SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
                initialMarginRate: ctx.adjustedMarginRequirements,
                marginValueUsd: ud60x18(marginValueUsd),
                maxSkew: ud60x18(ctx.fuzzMarketConfig.maxSkew),
                minTradeSize: ud60x18(ctx.fuzzMarketConfig.minTradeSize),
                price: ud60x18(ctx.fuzzMarketConfig.mockUsdPrice),
                isLong: isLong,
                shouldDiscountFees: true
            })
        );

        (,,, ctx.orderFeeUsdX18, ctx.settlementFeeUsdX18,) = perpsEngine.simulateTrade(
            ctx.tradingAccountId,
            ctx.fuzzMarketConfig.marketId,
            SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
            sizeDelta
        );

        ctx.amountToWithdraw =
            ctx.amountToWithdraw - ctx.orderFeeUsdX18.intoUint256() - ctx.settlementFeeUsdX18.intoUint256();

        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: ctx.tradingAccountId,
                marketId: ctx.fuzzMarketConfig.marketId,
                sizeDelta: sizeDelta
            })
        );

        (ctx.marginBalanceUsdX18, ctx.requiredInitialMarginUsdX18,, ctx.orderFeeUsdX18, ctx.settlementFeeUsdX18,) =
        perpsEngine.simulateTrade(
            ctx.tradingAccountId,
            ctx.fuzzMarketConfig.marketId,
            SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
            sizeDelta
        );

        ctx.mockSignedReport = getMockedSignedReport(ctx.fuzzMarketConfig.streamId, ctx.fuzzMarketConfig.mockUsdPrice);

        changePrank({ msgSender: marketOrderKeepers[ctx.fuzzMarketConfig.marketId] });

        perpsEngine.fillMarketOrder(ctx.tradingAccountId, ctx.fuzzMarketConfig.marketId, ctx.mockSignedReport);

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.InsufficientMargin.selector,
                ctx.tradingAccountId,
                int256(marginValueUsd) - int256(ctx.amountToWithdraw) - ctx.orderFeeUsdX18.intoSD59x18().intoInt256()
                    - ctx.settlementFeeUsdX18.intoSD59x18().intoInt256(),
                ctx.requiredInitialMarginUsdX18,
                0
            )
        });

        changePrank({ msgSender: users.naruto.account });
        perpsEngine.withdrawMargin({
            tradingAccountId: ctx.tradingAccountId,
            collateralType: address(usdz),
            amount: ctx.amountToWithdraw
        });
    }

    function testFuzz_GivenTheAccountMeetsTheMarginRequirement(
        uint256 amountToDeposit,
        uint256 amountToWithdraw
    )
        external
        givenTheAccountExists
        givenTheSenderIsAuthorized
        whenTheAmountIsNotZero
        givenThereIsEnoughMarginCollateral
    {
        // Test with wstEth that has 18 decimals

        amountToDeposit = bound({
            x: amountToDeposit,
            min: WSTETH_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(wstEth), WSTETH_DEPOSIT_CAP_X18)
        });
        amountToWithdraw = bound({ x: amountToWithdraw, min: 1, max: amountToDeposit });
        deal({ token: address(wstEth), to: users.naruto.account, give: amountToDeposit });

        uint128 tradingAccountId = createAccountAndDeposit(amountToDeposit, address(wstEth));

        // it should emit a {LogWithdrawMargin} event
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit TradingAccountBranch.LogWithdrawMargin(
            users.naruto.account, tradingAccountId, address(wstEth), amountToWithdraw
        );

        // it should transfer the withdrawn amount to the sender
        expectCallToTransfer(wstEth, users.naruto.account, amountToWithdraw);
        perpsEngine.withdrawMargin(tradingAccountId, address(wstEth), amountToWithdraw);

        uint256 expectedMargin =
            convertTokenAmountToUd60x18(address(wstEth), amountToDeposit - amountToWithdraw).intoUint256();
        uint256 newMarginCollateralBalance = convertUd60x18ToTokenAmount(
            address(wstEth), perpsEngine.getAccountMarginCollateralBalance(tradingAccountId, address(wstEth))
        );

        // it should decrease the margin collateral balance
        assertEq(expectedMargin, newMarginCollateralBalance, "withdrawMargin");

        // Test with usdc that has 6 decimals

        amountToDeposit = bound({
            x: amountToDeposit,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });
        amountToWithdraw = bound({ x: amountToWithdraw, min: 1, max: amountToDeposit });
        deal({ token: address(usdc), to: users.naruto.account, give: amountToDeposit });

        tradingAccountId = createAccountAndDeposit(amountToDeposit, address(usdc));

        // it should emit a {LogWithdrawMargin} event
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit TradingAccountBranch.LogWithdrawMargin(
            users.naruto.account, tradingAccountId, address(usdc), amountToWithdraw
        );

        // it should transfer the withdrawn amount to the sender
        expectCallToTransfer(usdc, users.naruto.account, amountToWithdraw);
        perpsEngine.withdrawMargin(tradingAccountId, address(usdc), amountToWithdraw);

        expectedMargin = convertTokenAmountToUd60x18(address(usdc), amountToDeposit - amountToWithdraw).intoUint256();
        newMarginCollateralBalance =
            perpsEngine.getAccountMarginCollateralBalance(tradingAccountId, address(usdc)).intoUint256();

        // it should decrease the margin collateral balance
        assertEq(expectedMargin, newMarginCollateralBalance, "withdrawMargin");
    }
}
