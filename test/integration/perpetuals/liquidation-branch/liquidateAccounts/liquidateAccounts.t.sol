// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { LiquidationBranch } from "@zaros/perpetuals/branches/LiquidationBranch.sol";
import { MarketOrder } from "@zaros/perpetuals/leaves/MarketOrder.sol";
import { Position } from "@zaros/perpetuals/leaves/Position.sol";
import { Base_Test } from "test/Base.t.sol";
import { PerpMarket } from "@zaros/perpetuals/leaves/PerpMarket.sol";
import { TradingAccountHarness } from "test/harnesses/perpetuals/leaves/TradingAccountHarness.sol";
import { GlobalConfigurationHarness } from "test/harnesses/perpetuals/leaves/GlobalConfigurationHarness.sol";
import { PerpMarketHarness } from "test/harnesses/perpetuals/leaves/PerpMarketHarness.sol";
import { PositionHarness } from "test/harnesses/perpetuals/leaves/PositionHarness.sol";

// PRB Math dependencies
import { UD60x18 } from "@prb-math/UD60x18.sol";
import { SD59x18, sd59x18 } from "@prb-math/SD59x18.sol";

contract LiquidateAccounts_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function test_RevertGiven_TheSenderIsNotARegisteredLiquidator() external {
        uint128[] memory accountsIds = new uint128[](1);

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.LiquidatorNotRegistered.selector, users.naruto.account)
        });
        perpsEngine.liquidateAccounts({ accountsIds: accountsIds });
    }

    modifier givenTheSenderIsARegisteredLiquidator() {
        _;
    }

    function test_WhenTheAccountsIdsArrayIsEmpty() external givenTheSenderIsARegisteredLiquidator {
        uint128[] memory accountsIds;

        changePrank({ msgSender: liquidationKeeper });

        // it should return
        perpsEngine.liquidateAccounts({ accountsIds: accountsIds });
    }

    modifier whenTheAccountsIdsArrayIsNotEmpty() {
        _;
    }

    function test_RevertGiven_OneOfTheAccountsDoesNotExist()
        external
        givenTheSenderIsARegisteredLiquidator
        whenTheAccountsIdsArrayIsNotEmpty
    {
        uint128[] memory accountsIds = new uint128[](1);
        accountsIds[0] = 1;

        changePrank({ msgSender: liquidationKeeper });

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.AccountNotFound.selector, accountsIds[0], liquidationKeeper)
        });
        perpsEngine.liquidateAccounts({ accountsIds: accountsIds });
    }

    modifier givenAllAccountsExist() {
        _;
    }

    struct TestFuzz_GivenThereAreLiquidatableAccountsInTheArray_Context {
        MarketConfig fuzzMarketConfig;
        MarketConfig secondMarketConfig;
        uint256 marginValueUsd;
        uint256 initialMarginRate;
        uint128[] accountsIds;
        uint256 accountMarginValueUsd;
        uint128 tradingAccountId;
        PerpMarket.Data perpMarketData;
        int256 expectedLastFundingRate;
        int256 expectedLastFundingFeePerUnit;
        uint256 expectedLastFundingTime;
        uint128 nonLiquidatableTradingAccountId;
        MarketOrder.Data marketOrder;
        Position.Data expectedPosition;
        Position.Data position;
        UD60x18 openInterestX18;
        uint256 expectedOpenInterest;
        SD59x18 skewX18;
        int256 expectedSkew;
    }

    function testFuzz_GivenThereAreLiquidatableAccountsInTheArray(
        uint256 marketId,
        uint256 secondMarketId,
        bool isLong,
        uint256 amountOfTradingAccounts,
        uint256 timeDelta
    )
        external
        givenTheSenderIsARegisteredLiquidator
        whenTheAccountsIdsArrayIsNotEmpty
        givenAllAccountsExist
    {
        TestFuzz_GivenThereAreLiquidatableAccountsInTheArray_Context memory ctx;

        ctx.fuzzMarketConfig = getFuzzMarketConfig(marketId);
        ctx.secondMarketConfig = getFuzzMarketConfig(secondMarketId);

        vm.assume(ctx.fuzzMarketConfig.marketId != ctx.secondMarketConfig.marketId);

        amountOfTradingAccounts = bound({ x: amountOfTradingAccounts, min: 1, max: 10 });
        timeDelta = bound({ x: timeDelta, min: 1 seconds, max: 1 days });

        ctx.marginValueUsd = 10_000e18 / amountOfTradingAccounts;
        ctx.initialMarginRate = ctx.fuzzMarketConfig.imr;

        deal({ token: address(usdz), to: users.naruto.account, give: ctx.marginValueUsd });

        // last account id == 0
        ctx.accountsIds = new uint128[](amountOfTradingAccounts + 2);

        ctx.accountMarginValueUsd = ctx.marginValueUsd / (amountOfTradingAccounts + 1);

        for (uint256 i; i < amountOfTradingAccounts; i++) {
            ctx.tradingAccountId = createAccountAndDeposit(ctx.accountMarginValueUsd, address(usdz));

            openPosition(
                ctx.fuzzMarketConfig,
                ctx.tradingAccountId,
                ctx.initialMarginRate,
                ctx.accountMarginValueUsd / 2,
                isLong
            );

            openPosition(
                ctx.secondMarketConfig,
                ctx.tradingAccountId,
                ctx.secondMarketConfig.imr,
                ctx.accountMarginValueUsd / 2,
                isLong
            );

            ctx.accountsIds[i] = ctx.tradingAccountId;

            deal({ token: address(usdz), to: users.naruto.account, give: ctx.marginValueUsd });
        }

        setAccountsAsLiquidatable(ctx.fuzzMarketConfig, isLong);
        setAccountsAsLiquidatable(ctx.secondMarketConfig, isLong);

        ctx.nonLiquidatableTradingAccountId = createAccountAndDeposit(ctx.accountMarginValueUsd, address(usdz));
        ctx.accountsIds[amountOfTradingAccounts] = ctx.nonLiquidatableTradingAccountId;

        changePrank({ msgSender: liquidationKeeper });

        for (uint256 i; i < ctx.accountsIds.length; i++) {
            if (ctx.accountsIds[i] == ctx.nonLiquidatableTradingAccountId || ctx.accountsIds[i] == 0) {
                continue;
            }

            // it should emit a {LogLiquidateAccount} event
            vm.expectEmit({
                checkTopic1: true,
                checkTopic2: true,
                checkTopic3: false,
                checkData: false,
                emitter: address(perpsEngine)
            });

            emit LiquidationBranch.LogLiquidateAccount({
                keeper: liquidationKeeper,
                tradingAccountId: ctx.accountsIds[i],
                amountOfOpenPositions: 0,
                requiredMaintenanceMarginUsd: 0,
                marginBalanceUsd: 0,
                liquidatedCollateralUsd: 0,
                liquidationFeeUsd: 0
            });
        }

        skip(timeDelta);

        ctx.expectedLastFundingRate = perpsEngine.getFundingRate(ctx.fuzzMarketConfig.marketId).intoInt256();
        ctx.expectedLastFundingTime = block.timestamp;

        perpsEngine.liquidateAccounts(ctx.accountsIds);

        // it should update the market's funding values
        ctx.perpMarketData =
            PerpMarketHarness(address(perpsEngine)).exposed_PerpMarket_load(ctx.fuzzMarketConfig.marketId);
        assertEq(ctx.expectedLastFundingRate, ctx.perpMarketData.lastFundingRate, "last funding rate");
        assertEq(ctx.expectedLastFundingTime, ctx.perpMarketData.lastFundingTime, "last funding time");

        // it should update open interest value
        (,, ctx.openInterestX18) = perpsEngine.getOpenInterest(ctx.fuzzMarketConfig.marketId);
        ctx.expectedOpenInterest = sd59x18(
            PositionHarness(address(perpsEngine)).exposed_Position_load(
                ctx.nonLiquidatableTradingAccountId, ctx.fuzzMarketConfig.marketId
            ).size
        ).abs().intoUD60x18().intoUint256();
        assertEq(ctx.expectedOpenInterest, ctx.openInterestX18.intoUint256(), "open interest");

        // it should update skew value
        ctx.skewX18 = perpsEngine.getSkew(ctx.fuzzMarketConfig.marketId);
        ctx.expectedSkew = PositionHarness(address(perpsEngine)).exposed_Position_load(
            ctx.nonLiquidatableTradingAccountId, ctx.fuzzMarketConfig.marketId
        ).size;
        assertEq(ctx.expectedSkew, ctx.skewX18.intoInt256(), "skew");

        for (uint256 i; i < ctx.accountsIds.length; i++) {
            if (ctx.accountsIds[i] == ctx.nonLiquidatableTradingAccountId) {
                continue;
            }

            // it should delete any active market order
            ctx.marketOrder = perpsEngine.getActiveMarketOrder(ctx.accountsIds[i]);
            assertEq(ctx.marketOrder.marketId, 0);
            assertEq(ctx.marketOrder.sizeDelta, 0);
            assertEq(ctx.marketOrder.timestamp, 0);

            // it should close all active positions
            ctx.expectedPosition =
                Position.Data({ size: 0, lastInteractionPrice: 0, lastInteractionFundingFeePerUnit: 0 });
            ctx.position = PositionHarness(address(perpsEngine)).exposed_Position_load(
                ctx.accountsIds[i], ctx.fuzzMarketConfig.marketId
            );
            assertEq(ctx.expectedPosition.size, ctx.position.size, "position size");
            assertEq(ctx.expectedPosition.lastInteractionPrice, ctx.position.lastInteractionPrice, "position price");
            assertEq(
                ctx.expectedPosition.lastInteractionFundingFeePerUnit,
                ctx.position.lastInteractionFundingFeePerUnit,
                "position funding fee"
            );

            // it should remove the account's all active markets
            assertEq(
                0,
                TradingAccountHarness(address(perpsEngine)).workaround_getActiveMarketsIdsLength(ctx.accountsIds[i]),
                "active market id"
            );
            assertEq(
                0,
                GlobalConfigurationHarness(address(perpsEngine)).workaround_getAccountsIdsWithActivePositionsLength(),
                "accounts ids with active positions"
            );
        }
    }
}
