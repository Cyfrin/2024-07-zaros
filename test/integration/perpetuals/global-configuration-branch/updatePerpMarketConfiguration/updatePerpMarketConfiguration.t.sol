// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { Base_Test } from "test/Base.t.sol";
import { GlobalConfigurationBranch } from "@zaros/perpetuals/branches/GlobalConfigurationBranch.sol";
import { GlobalConfiguration } from "@zaros/perpetuals/leaves/GlobalConfiguration.sol";
import { OrderFees } from "@zaros/perpetuals/leaves/OrderFees.sol";
import { PerpMarket } from "@zaros/perpetuals/leaves/PerpMarket.sol";

contract UpdatePerpMarketConfiguration_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function testFuzz_RevertWhen_MarketIsNotInitialized(uint256 marketId) external {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        uint128 marketIdNotInitialized = uint128(FINAL_MARKET_ID) + 1;

        GlobalConfigurationBranch.UpdatePerpMarketConfigurationParams memory params = GlobalConfigurationBranch
            .UpdatePerpMarketConfigurationParams({
            name: fuzzMarketConfig.marketName,
            symbol: fuzzMarketConfig.marketSymbol,
            priceAdapter: fuzzMarketConfig.priceAdapter,
            initialMarginRateX18: fuzzMarketConfig.imr,
            maintenanceMarginRateX18: fuzzMarketConfig.mmr,
            maxOpenInterest: fuzzMarketConfig.maxOi,
            maxSkew: fuzzMarketConfig.maxSkew,
            maxFundingVelocity: fuzzMarketConfig.maxFundingVelocity,
            minTradeSizeX18: fuzzMarketConfig.minTradeSize,
            skewScale: fuzzMarketConfig.skewScale,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: fuzzMarketConfig.priceFeedHeartbeatSeconds
        });

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.PerpMarketNotInitialized.selector, marketIdNotInitialized)
        });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.updatePerpMarketConfiguration(marketIdNotInitialized, params);
    }

    modifier whenMarketIsInitialized() {
        _;
    }

    function testFuzz_RevertWhen_LengthOfNameIsZero(uint256 marketId) external whenMarketIsInitialized {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        GlobalConfigurationBranch.UpdatePerpMarketConfigurationParams memory params = GlobalConfigurationBranch
            .UpdatePerpMarketConfigurationParams({
            name: "",
            symbol: fuzzMarketConfig.marketSymbol,
            priceAdapter: fuzzMarketConfig.priceAdapter,
            initialMarginRateX18: fuzzMarketConfig.imr,
            maintenanceMarginRateX18: fuzzMarketConfig.mmr,
            maxOpenInterest: fuzzMarketConfig.maxOi,
            maxSkew: fuzzMarketConfig.maxSkew,
            maxFundingVelocity: fuzzMarketConfig.maxFundingVelocity,
            skewScale: fuzzMarketConfig.skewScale,
            minTradeSizeX18: fuzzMarketConfig.minTradeSize,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: fuzzMarketConfig.priceFeedHeartbeatSeconds
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "name") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.updatePerpMarketConfiguration(fuzzMarketConfig.marketId, params);
    }

    modifier whenLengthOfNameIsNotZero() {
        _;
    }

    function testFuzz_RevertWhen_LengthOfSymbolIsZero(uint256 marketId)
        external
        whenMarketIsInitialized
        whenLengthOfNameIsNotZero
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        GlobalConfigurationBranch.UpdatePerpMarketConfigurationParams memory params = GlobalConfigurationBranch
            .UpdatePerpMarketConfigurationParams({
            name: fuzzMarketConfig.marketName,
            symbol: "",
            priceAdapter: fuzzMarketConfig.priceAdapter,
            initialMarginRateX18: fuzzMarketConfig.imr,
            maintenanceMarginRateX18: fuzzMarketConfig.mmr,
            maxOpenInterest: fuzzMarketConfig.maxOi,
            maxSkew: fuzzMarketConfig.maxSkew,
            maxFundingVelocity: fuzzMarketConfig.maxFundingVelocity,
            skewScale: fuzzMarketConfig.skewScale,
            minTradeSizeX18: fuzzMarketConfig.minTradeSize,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: fuzzMarketConfig.priceFeedHeartbeatSeconds
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "symbol") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.updatePerpMarketConfiguration(fuzzMarketConfig.marketId, params);
    }

    modifier whenLengthOfSymbolIsNotZero() {
        _;
    }

    function testFuzz_RevertWhen_PriceAdapterIsZero(uint256 marketId)
        external
        whenMarketIsInitialized
        whenLengthOfNameIsNotZero
        whenLengthOfSymbolIsNotZero
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        GlobalConfigurationBranch.UpdatePerpMarketConfigurationParams memory params = GlobalConfigurationBranch
            .UpdatePerpMarketConfigurationParams({
            name: fuzzMarketConfig.marketName,
            symbol: fuzzMarketConfig.marketSymbol,
            priceAdapter: address(0),
            initialMarginRateX18: fuzzMarketConfig.imr,
            maintenanceMarginRateX18: fuzzMarketConfig.mmr,
            maxOpenInterest: fuzzMarketConfig.maxOi,
            maxSkew: fuzzMarketConfig.maxSkew,
            maxFundingVelocity: fuzzMarketConfig.maxFundingVelocity,
            skewScale: fuzzMarketConfig.skewScale,
            minTradeSizeX18: fuzzMarketConfig.minTradeSize,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: fuzzMarketConfig.priceFeedHeartbeatSeconds
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "priceAdapter") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.updatePerpMarketConfiguration(fuzzMarketConfig.marketId, params);
    }

    modifier whenPriceAdapterIsNotZero() {
        _;
    }

    function testFuzz_RevertWhen_MaintenanceMarginRateIsZero(uint256 marketId)
        external
        whenMarketIsInitialized
        whenLengthOfNameIsNotZero
        whenLengthOfSymbolIsNotZero
        whenPriceAdapterIsNotZero
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        GlobalConfigurationBranch.UpdatePerpMarketConfigurationParams memory params = GlobalConfigurationBranch
            .UpdatePerpMarketConfigurationParams({
            name: fuzzMarketConfig.marketName,
            symbol: fuzzMarketConfig.marketSymbol,
            priceAdapter: fuzzMarketConfig.priceAdapter,
            initialMarginRateX18: fuzzMarketConfig.imr,
            maintenanceMarginRateX18: 0,
            maxOpenInterest: fuzzMarketConfig.maxOi,
            maxSkew: fuzzMarketConfig.maxSkew,
            maxFundingVelocity: fuzzMarketConfig.maxFundingVelocity,
            skewScale: fuzzMarketConfig.skewScale,
            minTradeSizeX18: fuzzMarketConfig.minTradeSize,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: fuzzMarketConfig.priceFeedHeartbeatSeconds
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "maintenanceMarginRateX18") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.updatePerpMarketConfiguration(fuzzMarketConfig.marketId, params);
    }

    modifier whenMaintenanceMarginRateIsNotZero() {
        _;
    }

    function testFuzz_RevertWhen_MaxOpenInterestIsZero(uint256 marketId)
        external
        whenMarketIsInitialized
        whenLengthOfNameIsNotZero
        whenLengthOfSymbolIsNotZero
        whenPriceAdapterIsNotZero
        whenMaintenanceMarginRateIsNotZero
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        GlobalConfigurationBranch.UpdatePerpMarketConfigurationParams memory params = GlobalConfigurationBranch
            .UpdatePerpMarketConfigurationParams({
            name: fuzzMarketConfig.marketName,
            symbol: fuzzMarketConfig.marketSymbol,
            priceAdapter: fuzzMarketConfig.priceAdapter,
            initialMarginRateX18: fuzzMarketConfig.imr,
            maintenanceMarginRateX18: fuzzMarketConfig.mmr,
            maxOpenInterest: 0,
            maxSkew: fuzzMarketConfig.maxSkew,
            maxFundingVelocity: fuzzMarketConfig.maxFundingVelocity,
            skewScale: fuzzMarketConfig.skewScale,
            minTradeSizeX18: fuzzMarketConfig.minTradeSize,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: fuzzMarketConfig.priceFeedHeartbeatSeconds
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "maxOpenInterest") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.updatePerpMarketConfiguration(fuzzMarketConfig.marketId, params);
    }

    modifier whenMaxOpenInterestIsNotZero() {
        _;
    }

    function testFuzz_RevertWhen_MaxSkewIsZero(uint256 marketId)
        external
        whenMarketIsInitialized
        whenLengthOfNameIsNotZero
        whenLengthOfSymbolIsNotZero
        whenPriceAdapterIsNotZero
        whenMaintenanceMarginRateIsNotZero
        whenMaxOpenInterestIsNotZero
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        GlobalConfigurationBranch.UpdatePerpMarketConfigurationParams memory params = GlobalConfigurationBranch
            .UpdatePerpMarketConfigurationParams({
            name: fuzzMarketConfig.marketName,
            symbol: fuzzMarketConfig.marketSymbol,
            priceAdapter: fuzzMarketConfig.priceAdapter,
            initialMarginRateX18: fuzzMarketConfig.imr,
            maintenanceMarginRateX18: fuzzMarketConfig.mmr,
            maxOpenInterest: fuzzMarketConfig.maxOi,
            maxSkew: 0,
            maxFundingVelocity: fuzzMarketConfig.maxFundingVelocity,
            skewScale: fuzzMarketConfig.skewScale,
            minTradeSizeX18: fuzzMarketConfig.minTradeSize,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: fuzzMarketConfig.priceFeedHeartbeatSeconds
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "maxSkew") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.updatePerpMarketConfiguration(fuzzMarketConfig.marketId, params);
    }

    modifier whenMaxSkewIsNotZero() {
        _;
    }

    function testFuzz_RevertWhen_InitialMarginRateIsZero(uint256 marketId)
        external
        whenMarketIsInitialized
        whenLengthOfNameIsNotZero
        whenLengthOfSymbolIsNotZero
        whenPriceAdapterIsNotZero
        whenMaintenanceMarginRateIsNotZero
        whenMaxOpenInterestIsNotZero
        whenMaxSkewIsNotZero
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        GlobalConfigurationBranch.UpdatePerpMarketConfigurationParams memory params = GlobalConfigurationBranch
            .UpdatePerpMarketConfigurationParams({
            name: fuzzMarketConfig.marketName,
            symbol: fuzzMarketConfig.marketSymbol,
            priceAdapter: fuzzMarketConfig.priceAdapter,
            initialMarginRateX18: 0,
            maintenanceMarginRateX18: fuzzMarketConfig.mmr,
            maxOpenInterest: fuzzMarketConfig.maxOi,
            maxSkew: fuzzMarketConfig.maxSkew,
            maxFundingVelocity: fuzzMarketConfig.maxFundingVelocity,
            skewScale: fuzzMarketConfig.skewScale,
            minTradeSizeX18: fuzzMarketConfig.minTradeSize,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: fuzzMarketConfig.priceFeedHeartbeatSeconds
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "initialMarginRateX18") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.updatePerpMarketConfiguration(fuzzMarketConfig.marketId, params);
    }

    modifier whenInitialMarginRateIsNotZero() {
        _;
    }

    function testFuzz_RevertWhen_InitialMarginRateIsLessOrEqualToMaintenanceMargin(uint256 marketId)
        external
        whenMarketIsInitialized
        whenLengthOfNameIsNotZero
        whenLengthOfSymbolIsNotZero
        whenPriceAdapterIsNotZero
        whenMaintenanceMarginRateIsNotZero
        whenMaxOpenInterestIsNotZero
        whenMaxSkewIsNotZero
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        GlobalConfigurationBranch.UpdatePerpMarketConfigurationParams memory params = GlobalConfigurationBranch
            .UpdatePerpMarketConfigurationParams({
            name: fuzzMarketConfig.marketName,
            symbol: fuzzMarketConfig.marketSymbol,
            priceAdapter: fuzzMarketConfig.priceAdapter,
            initialMarginRateX18: 1,
            maintenanceMarginRateX18: 1,
            maxOpenInterest: fuzzMarketConfig.maxOi,
            maxSkew: fuzzMarketConfig.maxSkew,
            maxFundingVelocity: fuzzMarketConfig.maxFundingVelocity,
            skewScale: fuzzMarketConfig.skewScale,
            minTradeSizeX18: fuzzMarketConfig.minTradeSize,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: fuzzMarketConfig.priceFeedHeartbeatSeconds
        });

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.InitialMarginRateLessOrEqualThanMaintenanceMarginRate.selector)
        });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.updatePerpMarketConfiguration(fuzzMarketConfig.marketId, params);
    }

    modifier whenInitialMarginIsNotLessOrEqualToMaintenanceMargin() {
        _;
    }

    function testFuzz_RevertWhen_SkewScaleIsZero(uint256 marketId)
        external
        whenMarketIsInitialized
        whenLengthOfNameIsNotZero
        whenLengthOfSymbolIsNotZero
        whenPriceAdapterIsNotZero
        whenMaintenanceMarginRateIsNotZero
        whenMaxOpenInterestIsNotZero
        whenMaxSkewIsNotZero
        whenInitialMarginIsNotLessOrEqualToMaintenanceMargin
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        GlobalConfigurationBranch.UpdatePerpMarketConfigurationParams memory params = GlobalConfigurationBranch
            .UpdatePerpMarketConfigurationParams({
            name: fuzzMarketConfig.marketName,
            symbol: fuzzMarketConfig.marketSymbol,
            priceAdapter: fuzzMarketConfig.priceAdapter,
            initialMarginRateX18: fuzzMarketConfig.imr,
            maintenanceMarginRateX18: fuzzMarketConfig.mmr,
            maxOpenInterest: fuzzMarketConfig.maxOi,
            maxSkew: fuzzMarketConfig.maxSkew,
            maxFundingVelocity: fuzzMarketConfig.maxFundingVelocity,
            skewScale: 0,
            minTradeSizeX18: fuzzMarketConfig.minTradeSize,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: fuzzMarketConfig.priceFeedHeartbeatSeconds
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "skewScale") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.updatePerpMarketConfiguration(fuzzMarketConfig.marketId, params);
    }

    modifier whenSkewScaleIsNotZero() {
        _;
    }

    function testFuzz_RevertWhen_MinTradeSizeIsZero(uint256 marketId)
        external
        whenMarketIsInitialized
        whenLengthOfNameIsNotZero
        whenLengthOfSymbolIsNotZero
        whenPriceAdapterIsNotZero
        whenMaintenanceMarginRateIsNotZero
        whenMaxOpenInterestIsNotZero
        whenMaxSkewIsNotZero
        whenInitialMarginIsNotLessOrEqualToMaintenanceMargin
        whenSkewScaleIsNotZero
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        GlobalConfigurationBranch.UpdatePerpMarketConfigurationParams memory params = GlobalConfigurationBranch
            .UpdatePerpMarketConfigurationParams({
            name: fuzzMarketConfig.marketName,
            symbol: fuzzMarketConfig.marketSymbol,
            priceAdapter: fuzzMarketConfig.priceAdapter,
            initialMarginRateX18: fuzzMarketConfig.imr,
            maintenanceMarginRateX18: fuzzMarketConfig.mmr,
            maxOpenInterest: fuzzMarketConfig.maxOi,
            maxSkew: fuzzMarketConfig.maxSkew,
            maxFundingVelocity: fuzzMarketConfig.maxFundingVelocity,
            skewScale: fuzzMarketConfig.skewScale,
            minTradeSizeX18: 0,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: fuzzMarketConfig.priceFeedHeartbeatSeconds
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "minTradeSizeX18") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.updatePerpMarketConfiguration(fuzzMarketConfig.marketId, params);
    }

    modifier whenMinTradeSizeIsNotZero() {
        _;
    }

    function testFuzz_RevertWhen_MaxFundingVelocityIsZero(uint256 marketId)
        external
        whenMarketIsInitialized
        whenLengthOfNameIsNotZero
        whenLengthOfSymbolIsNotZero
        whenPriceAdapterIsNotZero
        whenMaintenanceMarginRateIsNotZero
        whenMaxOpenInterestIsNotZero
        whenMaxSkewIsNotZero
        whenInitialMarginIsNotLessOrEqualToMaintenanceMargin
        whenSkewScaleIsNotZero
        whenMinTradeSizeIsNotZero
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        GlobalConfigurationBranch.UpdatePerpMarketConfigurationParams memory params = GlobalConfigurationBranch
            .UpdatePerpMarketConfigurationParams({
            name: fuzzMarketConfig.marketName,
            symbol: fuzzMarketConfig.marketSymbol,
            priceAdapter: fuzzMarketConfig.priceAdapter,
            initialMarginRateX18: fuzzMarketConfig.imr,
            maintenanceMarginRateX18: fuzzMarketConfig.mmr,
            maxOpenInterest: fuzzMarketConfig.maxOi,
            maxSkew: fuzzMarketConfig.maxSkew,
            maxFundingVelocity: 0,
            skewScale: fuzzMarketConfig.skewScale,
            minTradeSizeX18: fuzzMarketConfig.minTradeSize,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: fuzzMarketConfig.priceFeedHeartbeatSeconds
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "maxFundingVelocity") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.updatePerpMarketConfiguration(fuzzMarketConfig.marketId, params);
    }

    modifier whenMaxFundingVelocityIsNotZero() {
        _;
    }

    function testFuzz_RevertWhen_PriceFeedHeartbeatSecondsIsZero(uint256 marketId)
        external
        whenMarketIsInitialized
        whenLengthOfNameIsNotZero
        whenLengthOfSymbolIsNotZero
        whenPriceAdapterIsNotZero
        whenMaintenanceMarginRateIsNotZero
        whenMaxOpenInterestIsNotZero
        whenMaxSkewIsNotZero
        whenInitialMarginIsNotLessOrEqualToMaintenanceMargin
        whenSkewScaleIsNotZero
        whenMinTradeSizeIsNotZero
        whenMaxFundingVelocityIsNotZero
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        GlobalConfigurationBranch.UpdatePerpMarketConfigurationParams memory params = GlobalConfigurationBranch
            .UpdatePerpMarketConfigurationParams({
            name: fuzzMarketConfig.marketName,
            symbol: fuzzMarketConfig.marketSymbol,
            priceAdapter: fuzzMarketConfig.priceAdapter,
            initialMarginRateX18: fuzzMarketConfig.imr,
            maintenanceMarginRateX18: fuzzMarketConfig.mmr,
            maxOpenInterest: fuzzMarketConfig.maxOi,
            maxSkew: fuzzMarketConfig.maxSkew,
            maxFundingVelocity: fuzzMarketConfig.maxFundingVelocity,
            skewScale: fuzzMarketConfig.skewScale,
            minTradeSizeX18: fuzzMarketConfig.minTradeSize,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: 0
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "priceFeedHeartbeatSeconds") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.updatePerpMarketConfiguration(fuzzMarketConfig.marketId, params);
    }

    function test_WhenPriceFeedHearbeatSecondsIsNotZero(uint256 marketId)
        external
        whenMarketIsInitialized
        whenLengthOfNameIsNotZero
        whenLengthOfSymbolIsNotZero
        whenPriceAdapterIsNotZero
        whenMaintenanceMarginRateIsNotZero
        whenMaxOpenInterestIsNotZero
        whenMaxSkewIsNotZero
        whenInitialMarginIsNotLessOrEqualToMaintenanceMargin
        whenSkewScaleIsNotZero
        whenMinTradeSizeIsNotZero
    {
        changePrank({ msgSender: users.owner.account });

        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        GlobalConfigurationBranch.UpdatePerpMarketConfigurationParams memory params = GlobalConfigurationBranch
            .UpdatePerpMarketConfigurationParams({
            name: "New market name",
            symbol: fuzzMarketConfig.marketSymbol,
            priceAdapter: fuzzMarketConfig.priceAdapter,
            initialMarginRateX18: fuzzMarketConfig.imr,
            maintenanceMarginRateX18: fuzzMarketConfig.mmr,
            maxOpenInterest: fuzzMarketConfig.maxOi,
            maxSkew: fuzzMarketConfig.maxSkew,
            maxFundingVelocity: fuzzMarketConfig.maxFundingVelocity,
            skewScale: fuzzMarketConfig.skewScale,
            minTradeSizeX18: fuzzMarketConfig.minTradeSize,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: fuzzMarketConfig.priceFeedHeartbeatSeconds
        });

        // it should emit {LogUpdatePerpMarketConfiguration} event
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit GlobalConfigurationBranch.LogUpdatePerpMarketConfiguration(
            users.owner.account, fuzzMarketConfig.marketId
        );

        // it should update perp market
        perpsEngine.updatePerpMarketConfiguration(fuzzMarketConfig.marketId, params);
    }
}
