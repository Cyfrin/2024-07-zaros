// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { PremiumReport } from "@zaros/external/chainlink/interfaces/IStreamsLookupCompatible.sol";
import { IVerifierProxy } from "@zaros/external/chainlink/interfaces/IVerifierProxy.sol";
import { Errors } from "@zaros/utils/Errors.sol";
import { OrderBranch } from "@zaros/perpetuals/branches/OrderBranch.sol";
import { MarketOrder } from "@zaros/perpetuals/leaves/MarketOrder.sol";
import { SettlementBranch } from "@zaros/perpetuals/branches/SettlementBranch.sol";
import { PerpMarket } from "@zaros/perpetuals/leaves/PerpMarket.sol";
import { Position } from "@zaros/perpetuals/leaves/Position.sol";
import { SettlementConfiguration } from "@zaros/perpetuals/leaves/SettlementConfiguration.sol";
import { Base_Test } from "test/Base.t.sol";
import { TradingAccountHarness } from "test/harnesses/perpetuals/leaves/TradingAccountHarness.sol";
import { GlobalConfigurationHarness } from "test/harnesses/perpetuals/leaves/GlobalConfigurationHarness.sol";
import { PerpMarketHarness } from "test/harnesses/perpetuals/leaves/PerpMarketHarness.sol";
import { PositionHarness } from "test/harnesses/perpetuals/leaves/PositionHarness.sol";

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";
import { SD59x18, sd59x18, unary } from "@prb-math/SD59x18.sol";

import { console } from "forge-std/console.sol";

contract FillMarketOrder_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function testFuzz_RevertGiven_TheSenderIsNotTheKeeper(
        uint256 initialMarginRate,
        uint256 marginValueUsd,
        bool isLong,
        uint256 marketId
    )
        external
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        initialMarginRate = bound({ x: initialMarginRate, min: fuzzMarketConfig.imr, max: MAX_MARGIN_REQUIREMENTS });
        marginValueUsd = bound({
            x: marginValueUsd,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });

        deal({ token: address(usdc), to: users.naruto.account, give: marginValueUsd });

        uint128 tradingAccountId = createAccountAndDeposit(marginValueUsd, address(usdc));
        int128 sizeDelta = fuzzOrderSizeDelta(
            FuzzOrderSizeDeltaParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                settlementConfigurationId: SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
                initialMarginRate: ud60x18(initialMarginRate),
                marginValueUsd: ud60x18(marginValueUsd),
                maxSkew: ud60x18(fuzzMarketConfig.maxSkew),
                minTradeSize: ud60x18(fuzzMarketConfig.minTradeSize),
                price: ud60x18(fuzzMarketConfig.mockUsdPrice),
                isLong: isLong,
                shouldDiscountFees: true
            })
        );

        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                sizeDelta: sizeDelta
            })
        );

        bytes memory mockSignedReport =
            getMockedSignedReport(fuzzMarketConfig.streamId, fuzzMarketConfig.mockUsdPrice);
        address marketOrderKeeper = marketOrderKeepers[fuzzMarketConfig.marketId];

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.OnlyKeeper.selector, users.naruto.account, marketOrderKeeper)
        });
        perpsEngine.fillMarketOrder(tradingAccountId, fuzzMarketConfig.marketId, mockSignedReport);
    }

    modifier givenTheSenderIsTheKeeper() {
        _;
    }

    function testFuzz_RevertGiven_TheMarketOrderDoesNotExist(
        uint256 marginValueUsd,
        uint256 marketId
    )
        external
        givenTheSenderIsTheKeeper
        givenTheMarketOrderExists
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);
        marginValueUsd = bound({
            x: marginValueUsd,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });

        deal({ token: address(usdc), to: users.naruto.account, give: marginValueUsd });

        uint128 tradingAccountId = createAccountAndDeposit(marginValueUsd, address(usdc));

        bytes memory mockSignedReport =
            getMockedSignedReport(fuzzMarketConfig.streamId, fuzzMarketConfig.mockUsdPrice);
        address marketOrderKeeper = marketOrderKeepers[fuzzMarketConfig.marketId];

        changePrank({ msgSender: marketOrderKeeper });
        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.NoActiveMarketOrder.selector, tradingAccountId) });
        perpsEngine.fillMarketOrder(tradingAccountId, fuzzMarketConfig.marketId, mockSignedReport);
    }

    modifier givenTheMarketOrderExists() {
        _;
    }

    function testFuzz_RevertGiven_ThePerpMarketIsDisabled(
        uint256 initialMarginRate,
        uint256 marginValueUsd,
        bool isLong,
        uint256 marketId
    )
        external
        givenTheSenderIsTheKeeper
        givenTheMarketOrderExists
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);
        initialMarginRate = bound({ x: initialMarginRate, min: fuzzMarketConfig.imr, max: MAX_MARGIN_REQUIREMENTS });
        marginValueUsd = bound({
            x: marginValueUsd,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });

        deal({ token: address(usdc), to: users.naruto.account, give: marginValueUsd });

        uint128 tradingAccountId = createAccountAndDeposit(marginValueUsd, address(usdc));
        int128 sizeDelta = fuzzOrderSizeDelta(
            FuzzOrderSizeDeltaParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                settlementConfigurationId: SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
                initialMarginRate: ud60x18(initialMarginRate),
                marginValueUsd: ud60x18(marginValueUsd),
                maxSkew: ud60x18(fuzzMarketConfig.maxSkew),
                minTradeSize: ud60x18(fuzzMarketConfig.minTradeSize),
                price: ud60x18(fuzzMarketConfig.mockUsdPrice),
                isLong: isLong,
                shouldDiscountFees: true
            })
        );

        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                sizeDelta: sizeDelta
            })
        );

        bytes memory mockSignedReport =
            getMockedSignedReport(fuzzMarketConfig.streamId, fuzzMarketConfig.mockUsdPrice);
        address marketOrderKeeper = marketOrderKeepers[fuzzMarketConfig.marketId];

        changePrank({ msgSender: users.owner.account });
        perpsEngine.updatePerpMarketStatus({ marketId: fuzzMarketConfig.marketId, enable: false });

        changePrank({ msgSender: marketOrderKeeper });
        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.PerpMarketDisabled.selector, fuzzMarketConfig.marketId)
        });
        perpsEngine.fillMarketOrder(tradingAccountId, fuzzMarketConfig.marketId, mockSignedReport);
    }

    modifier givenThePerpMarketIsEnabled() {
        _;
    }

    function testFuzz_RevertGiven_TheSettlementStrategyIsDisabled(
        uint256 initialMarginRate,
        uint256 marginValueUsd,
        bool isLong,
        uint256 marketId
    )
        external
        givenTheSenderIsTheKeeper
        givenTheMarketOrderExists
        givenThePerpMarketIsEnabled
        givenTheSettlementStrategyIsEnabled
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);
        initialMarginRate = bound({ x: initialMarginRate, min: fuzzMarketConfig.imr, max: MAX_MARGIN_REQUIREMENTS });
        marginValueUsd = bound({
            x: marginValueUsd,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });

        deal({ token: address(usdc), to: users.naruto.account, give: marginValueUsd });

        uint128 tradingAccountId = createAccountAndDeposit(marginValueUsd, address(usdc));
        int128 sizeDelta = fuzzOrderSizeDelta(
            FuzzOrderSizeDeltaParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                settlementConfigurationId: SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
                initialMarginRate: ud60x18(initialMarginRate),
                marginValueUsd: ud60x18(marginValueUsd),
                maxSkew: ud60x18(fuzzMarketConfig.maxSkew),
                minTradeSize: ud60x18(fuzzMarketConfig.minTradeSize),
                price: ud60x18(fuzzMarketConfig.mockUsdPrice),
                isLong: isLong,
                shouldDiscountFees: true
            })
        );

        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                sizeDelta: sizeDelta
            })
        );

        bytes memory mockSignedReport =
            getMockedSignedReport(fuzzMarketConfig.streamId, fuzzMarketConfig.mockUsdPrice);
        address marketOrderKeeper = marketOrderKeepers[fuzzMarketConfig.marketId];

        SettlementConfiguration.DataStreamsStrategy memory marketOrderConfigurationData = SettlementConfiguration
            .DataStreamsStrategy({
            chainlinkVerifier: IVerifierProxy(mockChainlinkVerifier),
            streamId: fuzzMarketConfig.streamId
        });
        SettlementConfiguration.Data memory marketOrderConfiguration = SettlementConfiguration.Data({
            strategy: SettlementConfiguration.Strategy.DATA_STREAMS_DEFAULT,
            isEnabled: false,
            fee: DEFAULT_SETTLEMENT_FEE,
            keeper: marketOrderKeepers[fuzzMarketConfig.marketId],
            data: abi.encode(marketOrderConfigurationData)
        });

        changePrank({ msgSender: users.owner.account });

        perpsEngine.updateSettlementConfiguration({
            marketId: fuzzMarketConfig.marketId,
            settlementConfigurationId: SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
            newSettlementConfiguration: marketOrderConfiguration
        });

        changePrank({ msgSender: marketOrderKeeper });
        // it should revert
        vm.expectRevert({ revertData: Errors.SettlementDisabled.selector });
        perpsEngine.fillMarketOrder(tradingAccountId, fuzzMarketConfig.marketId, mockSignedReport);
    }

    modifier givenTheSettlementStrategyIsEnabled() {
        _;
    }

    function testFuzz_RevertGiven_TheReportVerificationFails(
        uint256 initialMarginRate,
        uint256 marginValueUsd,
        bool isLong,
        uint256 marketId
    )
        external
        givenTheSenderIsTheKeeper
        givenTheMarketOrderExists
        givenThePerpMarketIsEnabled
        givenTheSettlementStrategyIsEnabled
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);
        initialMarginRate = bound({ x: initialMarginRate, min: fuzzMarketConfig.imr, max: MAX_MARGIN_REQUIREMENTS });
        marginValueUsd = bound({
            x: marginValueUsd,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });

        deal({ token: address(usdc), to: users.naruto.account, give: marginValueUsd });

        uint128 tradingAccountId = createAccountAndDeposit(marginValueUsd, address(usdc));
        int128 sizeDelta = fuzzOrderSizeDelta(
            FuzzOrderSizeDeltaParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                settlementConfigurationId: SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
                initialMarginRate: ud60x18(initialMarginRate),
                marginValueUsd: ud60x18(marginValueUsd),
                maxSkew: ud60x18(fuzzMarketConfig.maxSkew),
                minTradeSize: ud60x18(fuzzMarketConfig.minTradeSize),
                price: ud60x18(fuzzMarketConfig.mockUsdPrice),
                isLong: isLong,
                shouldDiscountFees: true
            })
        );

        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                sizeDelta: sizeDelta
            })
        );

        bytes memory mockSignedReport =
            getMockedSignedReport(fuzzMarketConfig.streamId, fuzzMarketConfig.mockUsdPrice);
        address marketOrderKeeper = marketOrderKeepers[fuzzMarketConfig.marketId];

        SettlementConfiguration.DataStreamsStrategy memory marketOrderConfigurationData = SettlementConfiguration
            .DataStreamsStrategy({ chainlinkVerifier: IVerifierProxy(address(1)), streamId: fuzzMarketConfig.streamId });
        SettlementConfiguration.Data memory marketOrderConfiguration = SettlementConfiguration.Data({
            strategy: SettlementConfiguration.Strategy.DATA_STREAMS_DEFAULT,
            isEnabled: true,
            fee: DEFAULT_SETTLEMENT_FEE,
            keeper: marketOrderKeeper,
            data: abi.encode(marketOrderConfigurationData)
        });

        changePrank({ msgSender: users.owner.account });

        perpsEngine.updateSettlementConfiguration({
            marketId: fuzzMarketConfig.marketId,
            settlementConfigurationId: SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
            newSettlementConfiguration: marketOrderConfiguration
        });

        changePrank({ msgSender: marketOrderKeeper });
        // it should revert
        vm.expectRevert();
        perpsEngine.fillMarketOrder(tradingAccountId, fuzzMarketConfig.marketId, mockSignedReport);
    }

    modifier givenTheReportVerificationPasses() {
        _;
    }

    function test_RevertWhen_TheMarketOrderIdMismatches()
        external
        givenTheSenderIsTheKeeper
        givenTheMarketOrderExists
        givenThePerpMarketIsEnabled
        givenTheSettlementStrategyIsEnabled
        givenTheReportVerificationPasses
    {
        // give naruto some tokens
        uint256 USER_STARTING_BALANCE = convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18);
        int128 USER_POS_SIZE_DELTA = 10e18;
        deal({ token: address(usdc), to: users.naruto.account, give: USER_STARTING_BALANCE });
        // naruto creates a trading account and deposits their tokens as collateral
        changePrank({ msgSender: users.naruto.account });
        uint128 tradingAccountId = createAccountAndDeposit(USER_STARTING_BALANCE, address(usdc));

        // naruto creates an open order in the BTC market
        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: tradingAccountId,
                marketId: BTC_USD_MARKET_ID,
                sizeDelta: USER_POS_SIZE_DELTA
            })
        );
        // some time passes and the order is not filled

        vm.warp(block.timestamp + 100_000_000_000 + 1);

        // at the same time:
        // 1) keeper creates a transaction to fill naruto's open BTC order
        // 2) naruto updates their open order to place it on ETH market
        // 2) gets executed first; naruto changes position size and market id
        int128 USER_POS_2_SIZE_DELTA = 5e18;
        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: tradingAccountId,
                marketId: ETH_USD_MARKET_ID,
                sizeDelta: USER_POS_2_SIZE_DELTA
            })
        );

        vm.expectRevert(
            abi.encodeWithSelector(Errors.OrderMarketIdMismatch.selector, BTC_USD_MARKET_ID, ETH_USD_MARKET_ID)
        );

        // 1) gets executed afterwards - the keeper is calling this
        // with the parameters of the first opened order, in this case
        // with BTC's market id and price !
        bytes memory mockSignedReport = getMockedSignedReport(BTC_USD_STREAM_ID, MOCK_BTC_USD_PRICE);
        changePrank({ msgSender: marketOrderKeepers[BTC_USD_MARKET_ID] });
        perpsEngine.fillMarketOrder(tradingAccountId, BTC_USD_MARKET_ID, mockSignedReport);
    }

    modifier whenTheMarketOrderIdMatches() {
        _;
    }

    function testFuzz_RevertGiven_TheDataStreamsReportIsInvalid(
        uint256 initialMarginRate,
        uint256 marginValueUsd,
        bool isLong,
        uint256 marketId
    )
        external
        givenTheSenderIsTheKeeper
        givenTheMarketOrderExists
        givenThePerpMarketIsEnabled
        givenTheSettlementStrategyIsEnabled
        givenTheReportVerificationPasses
        whenTheMarketOrderIdMatches
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        uint256 wrongMarketId = fuzzMarketConfig.marketId < FINAL_MARKET_ID
            ? fuzzMarketConfig.marketId + 1
            : fuzzMarketConfig.marketId - 1;

        uint256[2] memory marketsIdsRange;
        marketsIdsRange[0] = wrongMarketId;
        marketsIdsRange[1] = wrongMarketId;

        MarketConfig memory wrongMarketConfig = getFilteredMarketsConfig(marketsIdsRange)[0];

        initialMarginRate = bound({ x: initialMarginRate, min: fuzzMarketConfig.imr, max: MAX_MARGIN_REQUIREMENTS });
        marginValueUsd = bound({
            x: marginValueUsd,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });

        deal({ token: address(usdc), to: users.naruto.account, give: marginValueUsd });

        uint128 tradingAccountId = createAccountAndDeposit(marginValueUsd, address(usdc));
        int128 sizeDelta = fuzzOrderSizeDelta(
            FuzzOrderSizeDeltaParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                settlementConfigurationId: SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
                initialMarginRate: ud60x18(initialMarginRate),
                marginValueUsd: ud60x18(marginValueUsd),
                maxSkew: ud60x18(fuzzMarketConfig.maxSkew),
                minTradeSize: ud60x18(fuzzMarketConfig.minTradeSize),
                price: ud60x18(fuzzMarketConfig.mockUsdPrice),
                isLong: isLong,
                shouldDiscountFees: true
            })
        );

        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                sizeDelta: sizeDelta
            })
        );

        bytes memory mockSignedReport =
            getMockedSignedReport(wrongMarketConfig.streamId, wrongMarketConfig.mockUsdPrice);
        (, bytes memory mockReportData) = abi.decode(mockSignedReport, (bytes32[3], bytes));
        PremiumReport memory premiumReport = abi.decode(mockReportData, (PremiumReport));

        address marketOrderKeeper = marketOrderKeepers[fuzzMarketConfig.marketId];

        changePrank({ msgSender: marketOrderKeeper });
        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.InvalidDataStreamReport.selector, fuzzMarketConfig.streamId, premiumReport.feedId
            )
        });
        perpsEngine.fillMarketOrder(tradingAccountId, fuzzMarketConfig.marketId, mockSignedReport);
    }

    modifier givenTheDataStreamsReportIsValid() {
        _;
    }

    function testFuzz_RevertGiven_TheAccountWontMeetTheMarginRequirement(
        uint256 marginValueUsd,
        bool isLong,
        uint256 marketId
    )
        external
        givenTheSenderIsTheKeeper
        givenTheMarketOrderExists
        givenThePerpMarketIsEnabled
        givenTheSettlementStrategyIsEnabled
        givenTheReportVerificationPasses
        whenTheMarketOrderIdMatches
        givenTheDataStreamsReportIsValid
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        // avoids very small rounding errors in super edge cases
        UD60x18 adjustedMarginRequirements = ud60x18(fuzzMarketConfig.imr).mul(ud60x18(1.001e18));
        UD60x18 maxMarginValueUsd = adjustedMarginRequirements.mul(ud60x18(fuzzMarketConfig.maxSkew)).mul(
            ud60x18(fuzzMarketConfig.mockUsdPrice)
        );

        marginValueUsd =
            bound({ x: marginValueUsd, min: USDZ_MIN_DEPOSIT_MARGIN, max: maxMarginValueUsd.intoUint256() });

        deal({ token: address(usdz), to: users.naruto.account, give: marginValueUsd });

        uint128 tradingAccountId = createAccountAndDeposit(marginValueUsd, address(usdz));
        int128 sizeDelta = fuzzOrderSizeDelta(
            FuzzOrderSizeDeltaParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                settlementConfigurationId: SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
                initialMarginRate: adjustedMarginRequirements,
                marginValueUsd: ud60x18(marginValueUsd),
                maxSkew: ud60x18(fuzzMarketConfig.maxSkew),
                minTradeSize: ud60x18(fuzzMarketConfig.minTradeSize),
                price: ud60x18(fuzzMarketConfig.mockUsdPrice),
                isLong: isLong,
                shouldDiscountFees: true
            })
        );

        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                sizeDelta: sizeDelta
            })
        );

        UD60x18 newImrX18 = ud60x18(fuzzMarketConfig.imr).mul(ud60x18(1.1e18));
        UD60x18 newMmrX18 = ud60x18(fuzzMarketConfig.mmr).mul(ud60x18(1.1e18));

        changePrank({ msgSender: users.owner.account });
        updatePerpMarketMarginRequirements(fuzzMarketConfig.marketId, newImrX18, newMmrX18);

        (
            SD59x18 marginBalanceUsdX18,
            UD60x18 requiredInitialMarginUsdX18,
            ,
            UD60x18 orderFeeUsdX18,
            UD60x18 settlementFeeUsdX18,
        ) = perpsEngine.simulateTrade(
            tradingAccountId,
            fuzzMarketConfig.marketId,
            SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
            sizeDelta
        );

        bytes memory mockSignedReport =
            getMockedSignedReport(fuzzMarketConfig.streamId, fuzzMarketConfig.mockUsdPrice);

        address marketOrderKeeper = marketOrderKeepers[fuzzMarketConfig.marketId];

        changePrank({ msgSender: marketOrderKeeper });
        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.InsufficientMargin.selector,
                tradingAccountId,
                marginBalanceUsdX18.intoInt256(),
                requiredInitialMarginUsdX18,
                orderFeeUsdX18.add(settlementFeeUsdX18).intoUint256()
            )
        });
        perpsEngine.fillMarketOrder(tradingAccountId, fuzzMarketConfig.marketId, mockSignedReport);
    }

    modifier givenTheAccountWillMeetTheMarginRequirement() {
        _;
    }

    function testFuzz_RevertGiven_TheMarketsOILimitWillBeExceeded(
        uint256 initialMarginRate,
        uint256 marginValueUsd,
        bool isLong,
        uint256 marketId
    )
        external
        givenTheSenderIsTheKeeper
        givenTheMarketOrderExists
        givenThePerpMarketIsEnabled
        givenTheSettlementStrategyIsEnabled
        givenTheReportVerificationPasses
        whenTheMarketOrderIdMatches
        givenTheDataStreamsReportIsValid
        givenTheAccountWillMeetTheMarginRequirement
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        initialMarginRate = bound({ x: initialMarginRate, min: fuzzMarketConfig.imr, max: MAX_MARGIN_REQUIREMENTS });
        marginValueUsd = bound({
            x: marginValueUsd,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });

        deal({ token: address(usdc), to: users.naruto.account, give: marginValueUsd });

        uint128 tradingAccountId = createAccountAndDeposit(marginValueUsd, address(usdc));
        int128 sizeDelta = fuzzOrderSizeDelta(
            FuzzOrderSizeDeltaParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                settlementConfigurationId: SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
                initialMarginRate: ud60x18(initialMarginRate),
                marginValueUsd: ud60x18(marginValueUsd),
                maxSkew: ud60x18(fuzzMarketConfig.maxSkew),
                minTradeSize: ud60x18(fuzzMarketConfig.minTradeSize),
                price: ud60x18(fuzzMarketConfig.mockUsdPrice),
                isLong: isLong,
                shouldDiscountFees: true
            })
        );

        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                sizeDelta: sizeDelta
            })
        );

        changePrank({ msgSender: users.owner.account });
        UD60x18 sizeDeltaAbs = sd59x18(sizeDelta).abs().intoUD60x18();
        UD60x18 newMaxOi = sizeDeltaAbs.sub(ud60x18(1));
        updatePerpMarketMaxOi(fuzzMarketConfig.marketId, newMaxOi);

        bytes memory mockSignedReport =
            getMockedSignedReport(fuzzMarketConfig.streamId, fuzzMarketConfig.mockUsdPrice);
        address marketOrderKeeper = marketOrderKeepers[fuzzMarketConfig.marketId];

        changePrank({ msgSender: marketOrderKeeper });
        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.ExceedsOpenInterestLimit.selector, fuzzMarketConfig.marketId, newMaxOi, sizeDeltaAbs
            )
        });
        perpsEngine.fillMarketOrder(tradingAccountId, fuzzMarketConfig.marketId, mockSignedReport);
    }

    modifier givenTheMarketsOILimitWontBeExceeded() {
        _;
    }

    struct TestFuzz_GivenThePnlIsNegative_Context {
        MarketConfig fuzzMarketConfig;
        uint256 adjustedMarginRequirements;
        uint256 priceShiftBps;
        address marketOrderKeeper;
        uint128 tradingAccountId;
        int128 firstOrderSizeDelta;
        UD60x18 firstOrderFeeUsdX18;
        UD60x18 firstFillPriceX18;
        int256 firstOrderExpectedPnl;
        bytes firstMockSignedReport;
        int256 expectedLastFundingRate;
        int256 expectedLastFundingFeePerUnit;
        uint256 expectedLastFundingTime;
        PerpMarket.Data perpMarketData;
        uint256 expectedOpenInterest;
        UD60x18 openInterestX18;
        int256 expectedSkew;
        SD59x18 skewX18;
        uint128 expectedActiveMarketId;
        uint128 activeMarketId;
        uint128 expectedAccountIdWithActivePosition;
        uint128 accountIdWithActivePosition;
        Position.Data expectedPosition;
        Position.Data position;
        int256 expectedMarginBalanceUsd;
        SD59x18 marginBalanceUsdX18;
        uint256 newIndexPrice;
        int128 secondOrderSizeDelta;
        UD60x18 secondOrderFeeUsdX18;
        UD60x18 secondFillPriceX18;
        SD59x18 secondOrderExpectedPnlX18;
        bytes secondMockSignedReport;
        MarketOrder.Data marketOrder;
    }

    function testFuzz_GivenThePnlIsNegative(
        uint256 initialMarginRate,
        uint256 marginValueUsd,
        bool isLong,
        uint256 marketId,
        uint256 priceShiftRatio,
        uint256 timeDelta
    )
        external
        givenTheSenderIsTheKeeper
        givenTheMarketOrderExists
        givenThePerpMarketIsEnabled
        givenTheSettlementStrategyIsEnabled
        givenTheReportVerificationPasses
        whenTheMarketOrderIdMatches
        givenTheDataStreamsReportIsValid
        givenTheAccountWillMeetTheMarginRequirement
        givenTheMarketsOILimitWontBeExceeded
    {
        TestFuzz_GivenThePnlIsNegative_Context memory ctx;
        ctx.fuzzMarketConfig = getFuzzMarketConfig(marketId);
        ctx.adjustedMarginRequirements = ud60x18(ctx.fuzzMarketConfig.imr).mul(ud60x18(1.1e18)).intoUint256();

        priceShiftRatio = bound({ x: priceShiftRatio, min: 2, max: 100 });
        initialMarginRate =
            bound({ x: initialMarginRate, min: ctx.adjustedMarginRequirements, max: MAX_MARGIN_REQUIREMENTS });
        marginValueUsd = bound({
            x: marginValueUsd,
            min: USDZ_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdz), USDZ_DEPOSIT_CAP_X18)
        });
        timeDelta = bound({ x: timeDelta, min: 1 seconds, max: 1 days });

        ctx.priceShiftBps = ctx.adjustedMarginRequirements / priceShiftRatio;
        ctx.marketOrderKeeper = marketOrderKeepers[ctx.fuzzMarketConfig.marketId];

        deal({ token: address(usdz), to: users.naruto.account, give: marginValueUsd });

        ctx.tradingAccountId = createAccountAndDeposit(marginValueUsd, address(usdz));

        ctx.firstOrderSizeDelta = fuzzOrderSizeDelta(
            FuzzOrderSizeDeltaParams({
                tradingAccountId: ctx.tradingAccountId,
                marketId: ctx.fuzzMarketConfig.marketId,
                settlementConfigurationId: SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
                initialMarginRate: ud60x18(initialMarginRate),
                marginValueUsd: ud60x18(marginValueUsd),
                maxSkew: ud60x18(ctx.fuzzMarketConfig.maxSkew),
                minTradeSize: ud60x18(ctx.fuzzMarketConfig.minTradeSize),
                price: ud60x18(ctx.fuzzMarketConfig.mockUsdPrice),
                isLong: isLong,
                shouldDiscountFees: true
            })
        );

        (,,, ctx.firstOrderFeeUsdX18,,) = perpsEngine.simulateTrade(
            ctx.tradingAccountId,
            ctx.fuzzMarketConfig.marketId,
            SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
            ctx.firstOrderSizeDelta
        );

        ctx.firstFillPriceX18 = perpsEngine.getMarkPrice(
            ctx.fuzzMarketConfig.marketId, ctx.fuzzMarketConfig.mockUsdPrice, ctx.firstOrderSizeDelta
        );

        // first market order
        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: ctx.tradingAccountId,
                marketId: ctx.fuzzMarketConfig.marketId,
                sizeDelta: ctx.firstOrderSizeDelta
            })
        );

        ctx.firstMockSignedReport =
            getMockedSignedReport(ctx.fuzzMarketConfig.streamId, ctx.fuzzMarketConfig.mockUsdPrice);

        ctx.firstOrderExpectedPnl = int256(0);

        changePrank({ msgSender: ctx.marketOrderKeeper });

        // it should emit a {LogFillOrder} event
        // it should transfer the pnl and fees
        vm.expectEmit({ emitter: address(perpsEngine) });
        expectCallToTransfer(usdz, feeRecipients.settlementFeeRecipient, DEFAULT_SETTLEMENT_FEE);
        expectCallToTransfer(usdz, feeRecipients.orderFeeRecipient, ctx.firstOrderFeeUsdX18.intoUint256());
        emit SettlementBranch.LogFillOrder({
            sender: ctx.marketOrderKeeper,
            tradingAccountId: ctx.tradingAccountId,
            marketId: ctx.fuzzMarketConfig.marketId,
            sizeDelta: ctx.firstOrderSizeDelta,
            fillPrice: ctx.firstFillPriceX18.intoUint256(),
            orderFeeUsd: ctx.firstOrderFeeUsdX18.intoUint256(),
            settlementFeeUsd: DEFAULT_SETTLEMENT_FEE,
            pnl: ctx.firstOrderExpectedPnl,
            fundingFeePerUnit: ctx.expectedLastFundingFeePerUnit
        });
        // fill first order and open position
        perpsEngine.fillMarketOrder(ctx.tradingAccountId, ctx.fuzzMarketConfig.marketId, ctx.firstMockSignedReport);
        // it should update the funding values
        ctx.expectedLastFundingTime = block.timestamp;
        ctx.perpMarketData =
            PerpMarketHarness(address(perpsEngine)).exposed_PerpMarket_load(ctx.fuzzMarketConfig.marketId);
        assertEq(0, ctx.perpMarketData.lastFundingRate, "first fill: last funding rate");
        assertEq(0, ctx.perpMarketData.lastFundingFeePerUnit, "first fill: last funding fee per unit");
        assertEq(ctx.expectedLastFundingTime, ctx.perpMarketData.lastFundingTime, "first fill: last funding time");

        // it should update the open interest and skew
        ctx.expectedOpenInterest = sd59x18(ctx.firstOrderSizeDelta).abs().intoUD60x18().intoUint256();
        ctx.expectedSkew = ctx.firstOrderSizeDelta;
        (,, ctx.openInterestX18) = perpsEngine.getOpenInterest(ctx.fuzzMarketConfig.marketId);
        ctx.skewX18 = perpsEngine.getSkew(ctx.fuzzMarketConfig.marketId);
        assertAlmostEq(ctx.expectedOpenInterest, ctx.openInterestX18.intoUint256(), 1, "first fill: open interest");
        assertEq(ctx.expectedSkew, ctx.skewX18.intoInt256(), "first fill: skew");

        // it should update the account's active markets
        ctx.expectedActiveMarketId = ctx.fuzzMarketConfig.marketId;
        ctx.activeMarketId =
            TradingAccountHarness(address(perpsEngine)).workaround_getActiveMarketId(ctx.tradingAccountId, 0);
        assertEq(ctx.expectedActiveMarketId, ctx.activeMarketId, "first fill: active market id");
        ctx.expectedAccountIdWithActivePosition = ctx.tradingAccountId;
        ctx.accountIdWithActivePosition =
            GlobalConfigurationHarness(address(perpsEngine)).workaround_getAccountIdWithActivePositions(0);
        assertEq(
            ctx.expectedAccountIdWithActivePosition,
            ctx.accountIdWithActivePosition,
            "first fill: accounts ids with active positions"
        );

        // it should update the account's position
        ctx.expectedPosition = Position.Data({
            size: ctx.firstOrderSizeDelta,
            lastInteractionPrice: ctx.firstFillPriceX18.intoUint128(),
            lastInteractionFundingFeePerUnit: 0
        });
        ctx.position = PositionHarness(address(perpsEngine)).exposed_Position_load(
            ctx.tradingAccountId, ctx.fuzzMarketConfig.marketId
        );
        assertEq(ctx.expectedPosition.size, ctx.position.size, "first fill: position size");
        assertEq(
            ctx.expectedPosition.lastInteractionPrice, ctx.position.lastInteractionPrice, "first fill: position price"
        );
        assertEq(
            ctx.expectedPosition.lastInteractionFundingFeePerUnit,
            ctx.position.lastInteractionFundingFeePerUnit,
            "first fill: position funding fee"
        );

        // asserts initial upnl is zero
        assertTrue(
            perpsEngine.getPositionState(
                ctx.tradingAccountId, ctx.fuzzMarketConfig.marketId, ctx.fuzzMarketConfig.mockUsdPrice
            ).unrealizedPnlUsdX18.isZero()
        );

        // it should deduct the pnl and fees
        ctx.expectedMarginBalanceUsd = int256(marginValueUsd) + ctx.firstOrderExpectedPnl;
        (ctx.marginBalanceUsdX18,,,) = perpsEngine.getAccountMarginBreakdown(ctx.tradingAccountId);

        changePrank({ msgSender: users.naruto.account });

        ctx.newIndexPrice = isLong
            ? ud60x18(ctx.fuzzMarketConfig.mockUsdPrice).mul(ud60x18(1e18).sub(ud60x18(ctx.priceShiftBps))).intoUint256()
            : ud60x18(ctx.fuzzMarketConfig.mockUsdPrice).mul(ud60x18(1e18).add(ud60x18(ctx.priceShiftBps))).intoUint256();
        updateMockPriceFeed(ctx.fuzzMarketConfig.marketId, ctx.newIndexPrice);

        ctx.secondOrderSizeDelta = -ctx.firstOrderSizeDelta;

        (,,, ctx.secondOrderFeeUsdX18,,) = perpsEngine.simulateTrade(
            ctx.tradingAccountId,
            ctx.fuzzMarketConfig.marketId,
            SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
            ctx.secondOrderSizeDelta
        );

        ctx.secondFillPriceX18 =
            perpsEngine.getMarkPrice(ctx.fuzzMarketConfig.marketId, ctx.newIndexPrice, ctx.secondOrderSizeDelta);

        skip(timeDelta);
        ctx.expectedLastFundingRate = perpsEngine.getFundingRate(ctx.fuzzMarketConfig.marketId).intoInt256();
        ctx.expectedLastFundingFeePerUnit = PerpMarketHarness(address(perpsEngine))
            .exposed_getPendingFundingFeePerUnit(
            ctx.fuzzMarketConfig.marketId, sd59x18(ctx.expectedLastFundingRate), ctx.secondFillPriceX18
        ).intoInt256();
        ctx.expectedLastFundingTime = block.timestamp;

        // second market order
        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: ctx.tradingAccountId,
                marketId: ctx.fuzzMarketConfig.marketId,
                sizeDelta: ctx.secondOrderSizeDelta
            })
        );

        ctx.secondMockSignedReport = getMockedSignedReport(ctx.fuzzMarketConfig.streamId, ctx.newIndexPrice);

        ctx.secondOrderExpectedPnlX18 = ctx.secondFillPriceX18.intoSD59x18().sub(ctx.firstFillPriceX18.intoSD59x18())
            .mul(sd59x18(ctx.firstOrderSizeDelta)).add(
            sd59x18(ctx.expectedLastFundingFeePerUnit).mul(sd59x18(ctx.position.size))
        );

        changePrank({ msgSender: ctx.marketOrderKeeper });

        // it should emit a {LogFillOrder} event
        // it should transfer the pnl and fees
        vm.expectEmit({ emitter: address(perpsEngine) });
        expectCallToTransfer(usdz, feeRecipients.settlementFeeRecipient, DEFAULT_SETTLEMENT_FEE);
        expectCallToTransfer(usdz, feeRecipients.orderFeeRecipient, ctx.secondOrderFeeUsdX18.intoUint256());
        expectCallToTransfer(
            usdz,
            feeRecipients.marginCollateralRecipient,
            ctx.secondOrderExpectedPnlX18.abs().intoUD60x18().intoUint256()
        );
        emit SettlementBranch.LogFillOrder({
            sender: ctx.marketOrderKeeper,
            tradingAccountId: ctx.tradingAccountId,
            marketId: ctx.fuzzMarketConfig.marketId,
            sizeDelta: ctx.secondOrderSizeDelta,
            fillPrice: ctx.secondFillPriceX18.intoUint256(),
            orderFeeUsd: ctx.secondOrderFeeUsdX18.intoUint256(),
            settlementFeeUsd: DEFAULT_SETTLEMENT_FEE,
            pnl: ctx.secondOrderExpectedPnlX18.intoInt256(),
            fundingFeePerUnit: ctx.expectedLastFundingFeePerUnit
        });

        console.log("after second fill");

        // fill second order and close position
        perpsEngine.fillMarketOrder(ctx.tradingAccountId, ctx.fuzzMarketConfig.marketId, ctx.secondMockSignedReport);

        // it should update the funding values
        ctx.perpMarketData =
            PerpMarketHarness(address(perpsEngine)).exposed_PerpMarket_load(ctx.fuzzMarketConfig.marketId);
        assertEq(ctx.expectedLastFundingRate, ctx.perpMarketData.lastFundingRate, "second fill: last funding rate");
        assertEq(
            ctx.expectedLastFundingFeePerUnit,
            ctx.perpMarketData.lastFundingFeePerUnit,
            "second fill: last funding fee per unit"
        );
        assertEq(ctx.expectedLastFundingTime, ctx.perpMarketData.lastFundingTime, "second fill: last funding time");

        // it should update the open interest and skew
        ctx.expectedOpenInterest = 0;
        ctx.expectedSkew = 0;
        (,, ctx.openInterestX18) = perpsEngine.getOpenInterest(ctx.fuzzMarketConfig.marketId);
        ctx.skewX18 = perpsEngine.getSkew(ctx.fuzzMarketConfig.marketId);
        assertAlmostEq(ctx.expectedOpenInterest, ctx.openInterestX18.intoUint256(), 1, "second fill: open interest");
        assertEq(ctx.expectedSkew, ctx.skewX18.intoInt256(), "second fill: skew");

        // it should update the account's active markets
        assertEq(
            0,
            TradingAccountHarness(address(perpsEngine)).workaround_getActiveMarketsIdsLength(ctx.tradingAccountId),
            "second fill: active market id"
        );
        assertEq(
            0,
            GlobalConfigurationHarness(address(perpsEngine)).workaround_getAccountsIdsWithActivePositionsLength(),
            "second fill: accounts ids with active positions"
        );

        // it should update the account's position
        ctx.expectedPosition =
            Position.Data({ size: 0, lastInteractionPrice: 0, lastInteractionFundingFeePerUnit: 0 });
        ctx.position = PositionHarness(address(perpsEngine)).exposed_Position_load(
            ctx.tradingAccountId, ctx.fuzzMarketConfig.marketId
        );
        assertEq(ctx.expectedPosition.size, ctx.position.size, "second fill: position size");
        assertEq(
            ctx.expectedPosition.lastInteractionPrice,
            ctx.position.lastInteractionPrice,
            "second fill: position price"
        );
        assertEq(
            ctx.expectedPosition.lastInteractionFundingFeePerUnit,
            ctx.position.lastInteractionFundingFeePerUnit,
            "second fill: position funding fee"
        );

        // it should deduct the pnl and fees
        ctx.expectedMarginBalanceUsd =
            int256(marginValueUsd) + ctx.firstOrderExpectedPnl + ctx.secondOrderExpectedPnlX18.intoInt256();
        (ctx.marginBalanceUsdX18,,,) = perpsEngine.getAccountMarginBreakdown(ctx.tradingAccountId);

        // it should delete any active market order
        ctx.marketOrder = perpsEngine.getActiveMarketOrder(ctx.tradingAccountId);
        assertEq(ctx.marketOrder.marketId, 0);
        assertEq(ctx.marketOrder.sizeDelta, 0);
        assertEq(ctx.marketOrder.timestamp, 0);
    }

    struct TestFuzz_GivenThePnlIsPositive_Context {
        MarketConfig fuzzMarketConfig;
        uint256 adjustedMarginRequirements;
        uint256 priceShiftBps;
        address marketOrderKeeper;
        uint128 tradingAccountId;
        int128 firstOrderSizeDelta;
        UD60x18 firstOrderFeeUsdX18;
        UD60x18 firstFillPriceX18;
        int256 firstOrderExpectedPnl;
        bytes firstMockSignedReport;
        int256 expectedLastFundingRate;
        int256 expectedLastFundingFeePerUnit;
        uint256 expectedLastFundingTime;
        PerpMarket.Data perpMarketData;
        uint256 expectedOpenInterest;
        UD60x18 openInterestX18;
        int256 expectedSkew;
        SD59x18 skewX18;
        uint128 expectedActiveMarketId;
        uint128 activeMarketId;
        uint128 expectedAccountIdWithActivePosition;
        uint128 accountIdWithActivePosition;
        Position.Data expectedPosition;
        Position.Data position;
        int256 expectedMarginBalanceUsd;
        SD59x18 marginBalanceUsdX18;
        uint256 newIndexPrice;
        int128 secondOrderSizeDelta;
        UD60x18 secondOrderFeeUsdX18;
        UD60x18 secondFillPriceX18;
        SD59x18 secondOrderExpectedPnlX18;
        bytes secondMockSignedReport;
        MarketOrder.Data marketOrder;
    }

    function testFuzz_GivenThePnlIsPositive(
        uint256 initialMarginRate,
        uint256 marginValueUsd,
        bool isLong,
        uint256 marketId,
        uint256 priceShift,
        uint256 timeDelta
    )
        external
        givenTheSenderIsTheKeeper
        givenTheMarketOrderExists
        givenThePerpMarketIsEnabled
        givenTheSettlementStrategyIsEnabled
        givenTheReportVerificationPasses
        whenTheMarketOrderIdMatches
        givenTheDataStreamsReportIsValid
        givenTheAccountWillMeetTheMarginRequirement
        givenTheMarketsOILimitWontBeExceeded
    {
        TestFuzz_GivenThePnlIsPositive_Context memory ctx;
        ctx.fuzzMarketConfig = getFuzzMarketConfig(marketId);
        ctx.adjustedMarginRequirements = ud60x18(ctx.fuzzMarketConfig.imr).mul(ud60x18(1.001e18)).intoUint256();

        priceShift = bound({ x: priceShift, min: 1.1e18, max: 10e18 });
        initialMarginRate =
            bound({ x: initialMarginRate, min: ctx.adjustedMarginRequirements, max: MAX_MARGIN_REQUIREMENTS });
        marginValueUsd = bound({
            x: marginValueUsd,
            min: USDZ_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdz), USDZ_DEPOSIT_CAP_X18)
        });
        timeDelta = bound({ x: timeDelta, min: 1 seconds, max: 1 days });

        ctx.marketOrderKeeper = marketOrderKeepers[ctx.fuzzMarketConfig.marketId];

        deal({ token: address(usdz), to: users.naruto.account, give: marginValueUsd });

        ctx.tradingAccountId = createAccountAndDeposit(marginValueUsd, address(usdz));

        ctx.firstOrderSizeDelta = fuzzOrderSizeDelta(
            FuzzOrderSizeDeltaParams({
                tradingAccountId: ctx.tradingAccountId,
                marketId: ctx.fuzzMarketConfig.marketId,
                settlementConfigurationId: SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
                initialMarginRate: ud60x18(initialMarginRate),
                marginValueUsd: ud60x18(marginValueUsd),
                maxSkew: ud60x18(ctx.fuzzMarketConfig.maxSkew),
                minTradeSize: ud60x18(ctx.fuzzMarketConfig.minTradeSize),
                price: ud60x18(ctx.fuzzMarketConfig.mockUsdPrice),
                isLong: isLong,
                shouldDiscountFees: true
            })
        );

        (,,, ctx.firstOrderFeeUsdX18,,) = perpsEngine.simulateTrade(
            ctx.tradingAccountId,
            ctx.fuzzMarketConfig.marketId,
            SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
            ctx.firstOrderSizeDelta
        );

        ctx.firstFillPriceX18 = perpsEngine.getMarkPrice(
            ctx.fuzzMarketConfig.marketId, ctx.fuzzMarketConfig.mockUsdPrice, ctx.firstOrderSizeDelta
        );

        // first market order
        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: ctx.tradingAccountId,
                marketId: ctx.fuzzMarketConfig.marketId,
                sizeDelta: ctx.firstOrderSizeDelta
            })
        );

        ctx.firstMockSignedReport =
            getMockedSignedReport(ctx.fuzzMarketConfig.streamId, ctx.fuzzMarketConfig.mockUsdPrice);

        ctx.firstOrderExpectedPnl = int256(0);

        changePrank({ msgSender: ctx.marketOrderKeeper });

        // it should emit a {LogFillOrder} event
        // it should transfer the pnl and fees
        vm.expectEmit({ emitter: address(perpsEngine) });
        expectCallToTransfer(usdz, feeRecipients.settlementFeeRecipient, DEFAULT_SETTLEMENT_FEE);
        expectCallToTransfer(usdz, feeRecipients.orderFeeRecipient, ctx.firstOrderFeeUsdX18.intoUint256());
        emit SettlementBranch.LogFillOrder({
            sender: ctx.marketOrderKeeper,
            tradingAccountId: ctx.tradingAccountId,
            marketId: ctx.fuzzMarketConfig.marketId,
            sizeDelta: ctx.firstOrderSizeDelta,
            fillPrice: ctx.firstFillPriceX18.intoUint256(),
            orderFeeUsd: ctx.firstOrderFeeUsdX18.intoUint256(),
            settlementFeeUsd: DEFAULT_SETTLEMENT_FEE,
            pnl: ctx.firstOrderExpectedPnl,
            fundingFeePerUnit: ctx.expectedLastFundingFeePerUnit
        });

        // fill first order and open position
        perpsEngine.fillMarketOrder(ctx.tradingAccountId, ctx.fuzzMarketConfig.marketId, ctx.firstMockSignedReport);
        console.log("after first fill");
        // it should update the funding values
        ctx.expectedLastFundingTime = block.timestamp;
        ctx.perpMarketData =
            PerpMarketHarness(address(perpsEngine)).exposed_PerpMarket_load(ctx.fuzzMarketConfig.marketId);
        assertEq(0, ctx.perpMarketData.lastFundingRate, "first fill: last funding rate");
        assertEq(0, ctx.perpMarketData.lastFundingFeePerUnit, "first fill: last funding fee per unit");
        assertEq(ctx.expectedLastFundingTime, ctx.perpMarketData.lastFundingTime, "first fill: last funding time");

        // it should update the open interest and skew
        ctx.expectedOpenInterest = sd59x18(ctx.firstOrderSizeDelta).abs().intoUD60x18().intoUint256();
        ctx.expectedSkew = ctx.firstOrderSizeDelta;
        (,, ctx.openInterestX18) = perpsEngine.getOpenInterest(ctx.fuzzMarketConfig.marketId);
        ctx.skewX18 = perpsEngine.getSkew(ctx.fuzzMarketConfig.marketId);
        assertAlmostEq(ctx.expectedOpenInterest, ctx.openInterestX18.intoUint256(), 1, "first fill: open interest");
        assertEq(ctx.expectedSkew, ctx.skewX18.intoInt256(), "first fill: skew");

        // it should update the account's active markets
        ctx.expectedActiveMarketId = ctx.fuzzMarketConfig.marketId;
        ctx.activeMarketId =
            TradingAccountHarness(address(perpsEngine)).workaround_getActiveMarketId(ctx.tradingAccountId, 0);
        assertEq(ctx.expectedActiveMarketId, ctx.activeMarketId, "first fill: active market id");
        ctx.expectedAccountIdWithActivePosition = ctx.tradingAccountId;
        ctx.accountIdWithActivePosition =
            GlobalConfigurationHarness(address(perpsEngine)).workaround_getAccountIdWithActivePositions(0);

        assertEq(
            ctx.expectedAccountIdWithActivePosition,
            ctx.accountIdWithActivePosition,
            "first fill: accounts ids with active positions"
        );

        // it should update the account's position
        ctx.expectedPosition = Position.Data({
            size: ctx.firstOrderSizeDelta,
            lastInteractionPrice: ctx.firstFillPriceX18.intoUint128(),
            lastInteractionFundingFeePerUnit: 0
        });
        ctx.position = PositionHarness(address(perpsEngine)).exposed_Position_load(
            ctx.tradingAccountId, ctx.fuzzMarketConfig.marketId
        );
        assertEq(ctx.expectedPosition.size, ctx.position.size, "first fill: position size");
        assertEq(
            ctx.expectedPosition.lastInteractionPrice, ctx.position.lastInteractionPrice, "first fill: position price"
        );
        assertEq(
            ctx.expectedPosition.lastInteractionFundingFeePerUnit,
            ctx.position.lastInteractionFundingFeePerUnit,
            "first fill: position funding fee"
        );

        // it should deduct fees
        ctx.expectedMarginBalanceUsd = int256(marginValueUsd) + ctx.firstOrderExpectedPnl
            - int256(ctx.firstOrderFeeUsdX18.intoUint256()) - int256(uint256(DEFAULT_SETTLEMENT_FEE));
        (ctx.marginBalanceUsdX18,,,) = perpsEngine.getAccountMarginBreakdown(ctx.tradingAccountId);
        assertEq(ctx.expectedMarginBalanceUsd, ctx.marginBalanceUsdX18.intoInt256(), "first fill: margin balance");

        changePrank({ msgSender: users.naruto.account });

        ctx.newIndexPrice = isLong
            ? ud60x18(ctx.fuzzMarketConfig.mockUsdPrice).mul(ud60x18(priceShift)).intoUint256()
            : ud60x18(ctx.fuzzMarketConfig.mockUsdPrice).div(ud60x18(priceShift)).intoUint256();
        updateMockPriceFeed(ctx.fuzzMarketConfig.marketId, ctx.newIndexPrice);

        ctx.secondOrderSizeDelta = -ctx.firstOrderSizeDelta;

        (,,, ctx.secondOrderFeeUsdX18,,) = perpsEngine.simulateTrade(
            ctx.tradingAccountId,
            ctx.fuzzMarketConfig.marketId,
            SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
            ctx.secondOrderSizeDelta
        );

        ctx.secondFillPriceX18 =
            perpsEngine.getMarkPrice(ctx.fuzzMarketConfig.marketId, ctx.newIndexPrice, ctx.secondOrderSizeDelta);

        skip(timeDelta);
        ctx.expectedLastFundingRate = perpsEngine.getFundingRate(ctx.fuzzMarketConfig.marketId).intoInt256();
        ctx.expectedLastFundingFeePerUnit = PerpMarketHarness(address(perpsEngine))
            .exposed_getPendingFundingFeePerUnit(
            ctx.fuzzMarketConfig.marketId, sd59x18(ctx.expectedLastFundingRate), ctx.secondFillPriceX18
        ).intoInt256();
        ctx.expectedLastFundingTime = block.timestamp;

        // second market order
        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: ctx.tradingAccountId,
                marketId: ctx.fuzzMarketConfig.marketId,
                sizeDelta: ctx.secondOrderSizeDelta
            })
        );

        ctx.secondMockSignedReport = getMockedSignedReport(ctx.fuzzMarketConfig.streamId, ctx.newIndexPrice);

        ctx.secondOrderExpectedPnlX18 = ctx.secondFillPriceX18.intoSD59x18().sub(ctx.firstFillPriceX18.intoSD59x18())
            .mul(sd59x18(ctx.firstOrderSizeDelta)).add(
            sd59x18(ctx.expectedLastFundingFeePerUnit).mul(sd59x18(ctx.position.size))
        );

        changePrank({ msgSender: ctx.marketOrderKeeper });

        // it should emit a {LogFillOrder} event
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit SettlementBranch.LogFillOrder({
            sender: ctx.marketOrderKeeper,
            tradingAccountId: ctx.tradingAccountId,
            marketId: ctx.fuzzMarketConfig.marketId,
            sizeDelta: ctx.secondOrderSizeDelta,
            fillPrice: ctx.secondFillPriceX18.intoUint256(),
            orderFeeUsd: ctx.secondOrderFeeUsdX18.intoUint256(),
            settlementFeeUsd: DEFAULT_SETTLEMENT_FEE,
            pnl: ctx.secondOrderExpectedPnlX18.intoInt256(),
            fundingFeePerUnit: ctx.expectedLastFundingFeePerUnit
        });
        console.log("before second fill");
        // fill second order and close position
        perpsEngine.fillMarketOrder(ctx.tradingAccountId, ctx.fuzzMarketConfig.marketId, ctx.secondMockSignedReport);
        console.log("after second fill");

        // it should update the funding values
        ctx.perpMarketData =
            PerpMarketHarness(address(perpsEngine)).exposed_PerpMarket_load(ctx.fuzzMarketConfig.marketId);
        assertEq(ctx.expectedLastFundingRate, ctx.perpMarketData.lastFundingRate, "second fill: last funding rate");
        assertEq(
            ctx.expectedLastFundingFeePerUnit,
            ctx.perpMarketData.lastFundingFeePerUnit,
            "second fill: last funding fee per unit"
        );

        // it should update the open interest and skew
        ctx.expectedOpenInterest = 0;
        ctx.expectedSkew = 0;
        (,, ctx.openInterestX18) = perpsEngine.getOpenInterest(ctx.fuzzMarketConfig.marketId);
        ctx.skewX18 = perpsEngine.getSkew(ctx.fuzzMarketConfig.marketId);
        assertAlmostEq(ctx.expectedOpenInterest, ctx.openInterestX18.intoUint256(), 1, "second fill: open interest");
        assertEq(ctx.expectedSkew, ctx.skewX18.intoInt256(), "second fill: skew");

        // it should update the account's active markets
        assertEq(
            0,
            TradingAccountHarness(address(perpsEngine)).workaround_getActiveMarketsIdsLength(ctx.tradingAccountId),
            "second fill: active market id"
        );
        assertEq(
            0,
            GlobalConfigurationHarness(address(perpsEngine)).workaround_getAccountsIdsWithActivePositionsLength(),
            "second fill: accounts ids with active positions"
        );

        // it should update the account's position
        ctx.expectedPosition =
            Position.Data({ size: 0, lastInteractionPrice: 0, lastInteractionFundingFeePerUnit: 0 });
        ctx.position = PositionHarness(address(perpsEngine)).exposed_Position_load(
            ctx.tradingAccountId, ctx.fuzzMarketConfig.marketId
        );
        assertEq(ctx.expectedPosition.size, ctx.position.size, "second fill: position size");
        assertEq(
            ctx.expectedPosition.lastInteractionPrice,
            ctx.position.lastInteractionPrice,
            "second fill: position price"
        );
        assertEq(
            ctx.expectedPosition.lastInteractionFundingFeePerUnit,
            ctx.position.lastInteractionFundingFeePerUnit,
            "second fill: position funding fee"
        );

        // it should add the pnl into the account's margin
        ctx.expectedMarginBalanceUsd = (
            int256(marginValueUsd) + ctx.firstOrderExpectedPnl + ctx.secondOrderExpectedPnlX18.intoInt256()
        )
            - (
                int256(ctx.firstOrderFeeUsdX18.intoUint256()) + int256(ctx.secondOrderFeeUsdX18.intoUint256())
                    + int256(uint256(DEFAULT_SETTLEMENT_FEE) * 2)
            );
        (ctx.marginBalanceUsdX18,,,) = perpsEngine.getAccountMarginBreakdown(ctx.tradingAccountId);
        assertEq(ctx.expectedMarginBalanceUsd, ctx.marginBalanceUsdX18.intoInt256(), "second fill: margin balance");

        // it should delete any active market order
        ctx.marketOrder = perpsEngine.getActiveMarketOrder(ctx.tradingAccountId);
        assertEq(ctx.marketOrder.marketId, 0);
        assertEq(ctx.marketOrder.sizeDelta, 0);
        assertEq(ctx.marketOrder.timestamp, 0);
    }

    modifier givenTheUserHasAnOpenPosition() {
        _;
    }

    modifier givenTheUserWillReduceThePosition() {
        _;
    }

    modifier givenTheMarginBalanceUsdIsUnderTheInitialMarginUsdRequired() {
        _;
    }

    struct Test_GivenTheMarginBalanceUsdIsOverTheMaintenanceMarginUsdRequired_Context {
        uint256 marketId;
        uint256 marginValueUsd;
        uint256 expectedLastFundingTime;
        uint256 expectedOpenInterest;
        int256 expectedSkew;
        int256 firstOrderExpectedPnl;
        SD59x18 secondOrderExpectedPnlX18;
        int256 expectedLastFundingRate;
        int256 expectedLastFundingFeePerUnit;
        uint128 tradingAccountId;
        int128 firstOrderSizeDelta;
        int128 secondOrderSizeDelta;
        bytes firstMockSignedReport;
        bytes secondMockSignedReport;
        UD60x18 openInterestX18;
        UD60x18 firstOrderFeeUsdX18;
        UD60x18 secondOrderFeeUsdX18;
        UD60x18 firstFillPriceX18;
        UD60x18 secondFillPriceX18;
        SD59x18 skewX18;
        MarketConfig fuzzMarketConfig;
        PerpMarket.Data perpMarketData;
        MarketOrder.Data marketOrder;
        Position.Data expectedPosition;
        Position.Data position;
        address marketOrderKeeper;
    }

    function test_RevertGiven_TheMarginBalanceUsdIsUnderTheMaintenanceMarginUsdRequired()
        external
        givenTheSenderIsTheKeeper
        givenTheMarketOrderExists
        givenThePerpMarketIsEnabled
        givenTheSettlementStrategyIsEnabled
        givenTheReportVerificationPasses
        givenTheDataStreamsReportIsValid
        givenTheAccountWillMeetTheMarginRequirement
        givenTheMarketsOILimitWontBeExceeded
        givenTheUserHasAnOpenPosition
        givenTheUserWillReduceThePosition
        givenTheMarginBalanceUsdIsUnderTheInitialMarginUsdRequired
    {
        Test_GivenTheMarginBalanceUsdIsOverTheMaintenanceMarginUsdRequired_Context memory ctx;

        ctx.marketId = BTC_USD_MARKET_ID;
        ctx.marginValueUsd = 100_000e18;

        deal({ token: address(usdz), to: users.naruto.account, give: ctx.marginValueUsd });

        // Config first fill order

        ctx.firstOrderSizeDelta = 10e18;
        ctx.fuzzMarketConfig = getFuzzMarketConfig(ctx.marketId);
        ctx.marketOrderKeeper = marketOrderKeepers[ctx.fuzzMarketConfig.marketId];
        ctx.tradingAccountId = createAccountAndDeposit(ctx.marginValueUsd, address(usdz));
        ctx.firstMockSignedReport =
            getMockedSignedReport(ctx.fuzzMarketConfig.streamId, ctx.fuzzMarketConfig.mockUsdPrice);

        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: ctx.tradingAccountId,
                marketId: ctx.fuzzMarketConfig.marketId,
                sizeDelta: ctx.firstOrderSizeDelta
            })
        );

        changePrank({ msgSender: ctx.marketOrderKeeper });

        perpsEngine.fillMarketOrder(ctx.tradingAccountId, ctx.fuzzMarketConfig.marketId, ctx.firstMockSignedReport);

        // Config second fill order

        changePrank({ msgSender: users.naruto.account });

        uint256 updatedPrice = MOCK_BTC_USD_PRICE - MOCK_BTC_USD_PRICE / 10;
        updateMockPriceFeed(BTC_USD_MARKET_ID, updatedPrice);

        // reduce the position with negative size delta
        ctx.secondOrderSizeDelta = -(ctx.firstOrderSizeDelta - ctx.firstOrderSizeDelta / 2);
        ctx.fuzzMarketConfig.mockUsdPrice = updatedPrice;

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.AccountIsLiquidatable.selector, ctx.tradingAccountId)
        });

        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: ctx.tradingAccountId,
                marketId: ctx.fuzzMarketConfig.marketId,
                sizeDelta: ctx.secondOrderSizeDelta
            })
        );
    }

    function test_GivenTheMarginBalanceUsdIsOverTheMaintenanceMarginUsdRequired()
        external
        givenTheSenderIsTheKeeper
        givenTheMarketOrderExists
        givenThePerpMarketIsEnabled
        givenTheSettlementStrategyIsEnabled
        givenTheReportVerificationPasses
        givenTheDataStreamsReportIsValid
        givenTheAccountWillMeetTheMarginRequirement
        givenTheMarketsOILimitWontBeExceeded
        givenTheUserHasAnOpenPosition
        givenTheUserWillReduceThePosition
        givenTheMarginBalanceUsdIsUnderTheInitialMarginUsdRequired
    {
        Test_GivenTheMarginBalanceUsdIsOverTheMaintenanceMarginUsdRequired_Context memory ctx;

        ctx.marketId = BTC_USD_MARKET_ID;
        ctx.marginValueUsd = 100_000e18;

        deal({ token: address(usdz), to: users.naruto.account, give: ctx.marginValueUsd });

        // Config first fill order

        ctx.fuzzMarketConfig = getFuzzMarketConfig(ctx.marketId);

        ctx.marketOrderKeeper = marketOrderKeepers[ctx.fuzzMarketConfig.marketId];

        ctx.tradingAccountId = createAccountAndDeposit(ctx.marginValueUsd, address(usdz));

        ctx.firstOrderSizeDelta = 10e18;

        (,,, ctx.firstOrderFeeUsdX18,,) = perpsEngine.simulateTrade(
            ctx.tradingAccountId,
            ctx.fuzzMarketConfig.marketId,
            SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
            ctx.firstOrderSizeDelta
        );

        ctx.firstFillPriceX18 = perpsEngine.getMarkPrice(
            ctx.fuzzMarketConfig.marketId, ctx.fuzzMarketConfig.mockUsdPrice, ctx.firstOrderSizeDelta
        );

        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: ctx.tradingAccountId,
                marketId: ctx.fuzzMarketConfig.marketId,
                sizeDelta: ctx.firstOrderSizeDelta
            })
        );

        ctx.firstOrderExpectedPnl = int256(0);

        ctx.firstMockSignedReport =
            getMockedSignedReport(ctx.fuzzMarketConfig.streamId, ctx.fuzzMarketConfig.mockUsdPrice);

        changePrank({ msgSender: ctx.marketOrderKeeper });

        // it should transfer the pnl and fees
        expectCallToTransfer(usdz, feeRecipients.settlementFeeRecipient, DEFAULT_SETTLEMENT_FEE);
        expectCallToTransfer(usdz, feeRecipients.orderFeeRecipient, ctx.firstOrderFeeUsdX18.intoUint256());

        // it should emit a {LogFillOrder} event
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit SettlementBranch.LogFillOrder({
            sender: ctx.marketOrderKeeper,
            tradingAccountId: ctx.tradingAccountId,
            marketId: ctx.fuzzMarketConfig.marketId,
            sizeDelta: ctx.firstOrderSizeDelta,
            fillPrice: ctx.firstFillPriceX18.intoUint256(),
            orderFeeUsd: ctx.firstOrderFeeUsdX18.intoUint256(),
            settlementFeeUsd: DEFAULT_SETTLEMENT_FEE,
            pnl: ctx.firstOrderExpectedPnl,
            fundingFeePerUnit: ctx.expectedLastFundingFeePerUnit
        });

        perpsEngine.fillMarketOrder(ctx.tradingAccountId, ctx.fuzzMarketConfig.marketId, ctx.firstMockSignedReport);

        // Config second fill order

        // asserts initial upnl is zero
        assertTrue(
            perpsEngine.getPositionState(
                ctx.tradingAccountId, ctx.fuzzMarketConfig.marketId, ctx.fuzzMarketConfig.mockUsdPrice
            ).unrealizedPnlUsdX18.isZero()
        );

        changePrank({ msgSender: users.naruto.account });

        // if changed this to "/10" instead of "/11" naruto would be liquidatable,
        // so this is just on the verge of being liquidated
        uint256 updatedPrice = MOCK_BTC_USD_PRICE - MOCK_BTC_USD_PRICE / 11;
        updateMockPriceFeed(BTC_USD_MARKET_ID, updatedPrice);

        // reduce the position with negative size delta
        ctx.secondOrderSizeDelta = -(ctx.firstOrderSizeDelta - ctx.firstOrderSizeDelta / 2);
        ctx.fuzzMarketConfig.mockUsdPrice = updatedPrice;

        ctx.secondFillPriceX18 = perpsEngine.getMarkPrice(
            ctx.fuzzMarketConfig.marketId, ctx.fuzzMarketConfig.mockUsdPrice, ctx.secondOrderSizeDelta
        );

        (,,, ctx.secondOrderFeeUsdX18,,) = perpsEngine.simulateTrade(
            ctx.tradingAccountId,
            ctx.fuzzMarketConfig.marketId,
            SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
            ctx.secondOrderSizeDelta
        );

        ctx.expectedLastFundingRate = perpsEngine.getFundingRate(ctx.fuzzMarketConfig.marketId).intoInt256();
        ctx.expectedLastFundingFeePerUnit = PerpMarketHarness(address(perpsEngine))
            .exposed_getPendingFundingFeePerUnit(
            ctx.fuzzMarketConfig.marketId, sd59x18(ctx.expectedLastFundingRate), ctx.secondFillPriceX18
        ).intoInt256();
        ctx.expectedLastFundingTime = block.timestamp;

        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: ctx.tradingAccountId,
                marketId: ctx.fuzzMarketConfig.marketId,
                sizeDelta: ctx.secondOrderSizeDelta
            })
        );

        ctx.secondMockSignedReport =
            getMockedSignedReport(ctx.fuzzMarketConfig.streamId, ctx.fuzzMarketConfig.mockUsdPrice);

        ctx.secondOrderExpectedPnlX18 = ctx.secondFillPriceX18.intoSD59x18().sub(ctx.firstFillPriceX18.intoSD59x18())
            .mul(sd59x18(ctx.firstOrderSizeDelta)).add(
            sd59x18(ctx.expectedLastFundingFeePerUnit).mul(sd59x18(ctx.position.size))
        );

        changePrank({ msgSender: ctx.marketOrderKeeper });

        // it should transfer the pnl and fees
        expectCallToTransfer(usdz, feeRecipients.settlementFeeRecipient, DEFAULT_SETTLEMENT_FEE);
        expectCallToTransfer(usdz, feeRecipients.orderFeeRecipient, ctx.secondOrderFeeUsdX18.intoUint256());

        // it should emit a {LogFillOrder} event
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit SettlementBranch.LogFillOrder({
            sender: ctx.marketOrderKeeper,
            tradingAccountId: ctx.tradingAccountId,
            marketId: ctx.fuzzMarketConfig.marketId,
            sizeDelta: ctx.secondOrderSizeDelta,
            fillPrice: ctx.secondFillPriceX18.intoUint256(),
            orderFeeUsd: ctx.secondOrderFeeUsdX18.intoUint256(),
            settlementFeeUsd: DEFAULT_SETTLEMENT_FEE,
            pnl: ctx.secondOrderExpectedPnlX18.intoInt256(),
            fundingFeePerUnit: ctx.expectedLastFundingFeePerUnit
        });

        perpsEngine.fillMarketOrder(ctx.tradingAccountId, ctx.fuzzMarketConfig.marketId, ctx.secondMockSignedReport);

        // it should update the funding values
        ctx.expectedLastFundingTime = block.timestamp;
        ctx.perpMarketData =
            PerpMarketHarness(address(perpsEngine)).exposed_PerpMarket_load(ctx.fuzzMarketConfig.marketId);
        assertEq(0, ctx.perpMarketData.lastFundingRate, "second fill: last funding rate");
        assertEq(0, ctx.perpMarketData.lastFundingFeePerUnit, "second fill: last funding fee per unit");
        assertEq(ctx.expectedLastFundingTime, ctx.perpMarketData.lastFundingTime, "second fill: last funding time");

        // it should update the open interest and skew
        ctx.expectedOpenInterest = uint128(ctx.firstOrderSizeDelta + ctx.secondOrderSizeDelta);
        ctx.expectedSkew = ctx.firstOrderSizeDelta + ctx.secondOrderSizeDelta;
        (,, ctx.openInterestX18) = perpsEngine.getOpenInterest(ctx.fuzzMarketConfig.marketId);
        ctx.skewX18 = perpsEngine.getSkew(ctx.fuzzMarketConfig.marketId);
        assertAlmostEq(ctx.expectedOpenInterest, ctx.openInterestX18.intoUint256(), 1, "second fill: open interest");
        assertEq(ctx.expectedSkew, ctx.skewX18.intoInt256(), "second fill: skew");

        // it should keep the account's active markets
        assertEq(
            1,
            TradingAccountHarness(address(perpsEngine)).workaround_getActiveMarketsIdsLength(ctx.tradingAccountId),
            "second fill: active market id"
        );
        assertEq(
            1,
            GlobalConfigurationHarness(address(perpsEngine)).workaround_getAccountsIdsWithActivePositionsLength(),
            "second fill: accounts ids with active positions"
        );

        // it should update the account's position
        ctx.expectedPosition = Position.Data({
            size: ctx.expectedSkew,
            lastInteractionPrice: ctx.secondFillPriceX18.intoUint128(),
            lastInteractionFundingFeePerUnit: 0
        });
        ctx.position = PositionHarness(address(perpsEngine)).exposed_Position_load(
            ctx.tradingAccountId, ctx.fuzzMarketConfig.marketId
        );
        assertEq(ctx.expectedPosition.size, ctx.position.size, "second fill: position size");
        assertEq(
            ctx.expectedPosition.lastInteractionPrice,
            ctx.position.lastInteractionPrice,
            "second fill: position price"
        );
        assertEq(
            ctx.expectedPosition.lastInteractionFundingFeePerUnit,
            ctx.position.lastInteractionFundingFeePerUnit,
            "second fill: position funding fee"
        );

        // it should delete the market order
        ctx.marketOrder = perpsEngine.getActiveMarketOrder(ctx.tradingAccountId);
        assertEq(ctx.marketOrder.marketId, 0);
        assertEq(ctx.marketOrder.sizeDelta, 0);
        assertEq(ctx.marketOrder.timestamp, 0);
    }
}
