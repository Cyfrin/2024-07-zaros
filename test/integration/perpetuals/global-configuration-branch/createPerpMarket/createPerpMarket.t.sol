// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { Base_Test } from "test/Base.t.sol";
import { GlobalConfigurationBranch } from "@zaros/perpetuals/branches/GlobalConfigurationBranch.sol";
import { GlobalConfiguration } from "@zaros/perpetuals/leaves/GlobalConfiguration.sol";
import { OrderFees } from "@zaros/perpetuals/leaves/OrderFees.sol";
import { PerpMarket } from "@zaros/perpetuals/leaves/PerpMarket.sol";
import { SettlementConfiguration } from "@zaros/perpetuals/leaves/SettlementConfiguration.sol";

contract CreatePerpMarket_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
    }

    function test_RevertWhen_MarketIdIsZero() external {
        SettlementConfiguration.Data memory offchainOrdersConfiguration;
        SettlementConfiguration.Data memory marketOrderConfiguration;

        GlobalConfigurationBranch.CreatePerpMarketParams memory params = GlobalConfigurationBranch
            .CreatePerpMarketParams({
            marketId: 0,
            name: "BTC/USD",
            symbol: "BTC",
            priceAdapter: address(0x20),
            initialMarginRateX18: 2,
            maintenanceMarginRateX18: 1,
            maxOpenInterest: 1,
            maxSkew: 1,
            maxFundingVelocity: 1,
            minTradeSizeX18: 1,
            skewScale: 1,
            marketOrderConfiguration: marketOrderConfiguration,
            offchainOrdersConfiguration: offchainOrdersConfiguration,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: 1
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "marketId") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.createPerpMarket(params);
    }

    modifier whenMarketIdIsNotZero() {
        _;
    }

    function test_RevertWhen_LengthOfNameIsZero() external whenMarketIdIsNotZero {
        SettlementConfiguration.Data memory offchainOrdersConfiguration;
        SettlementConfiguration.Data memory marketOrderConfiguration;

        GlobalConfigurationBranch.CreatePerpMarketParams memory params = GlobalConfigurationBranch
            .CreatePerpMarketParams({
            marketId: 1,
            name: "",
            symbol: "BTC",
            priceAdapter: address(0x20),
            initialMarginRateX18: 2,
            maintenanceMarginRateX18: 1,
            maxOpenInterest: 1,
            maxSkew: 1,
            maxFundingVelocity: 1,
            minTradeSizeX18: 1,
            skewScale: 1,
            marketOrderConfiguration: marketOrderConfiguration,
            offchainOrdersConfiguration: offchainOrdersConfiguration,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: 1
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "name") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.createPerpMarket(params);
    }

    modifier whenLengthOfNameIsNotZero() {
        _;
    }

    function test_RevertWhen_LengthOfSymbolIsZero() external whenMarketIdIsNotZero whenLengthOfNameIsNotZero {
        SettlementConfiguration.Data memory offchainOrdersConfiguration;
        SettlementConfiguration.Data memory marketOrderConfiguration;

        GlobalConfigurationBranch.CreatePerpMarketParams memory params = GlobalConfigurationBranch
            .CreatePerpMarketParams({
            marketId: 1,
            name: "BTC/USD",
            symbol: "",
            priceAdapter: address(0x20),
            initialMarginRateX18: 2,
            maintenanceMarginRateX18: 1,
            maxOpenInterest: 1,
            maxSkew: 1,
            maxFundingVelocity: 1,
            minTradeSizeX18: 1,
            skewScale: 1,
            marketOrderConfiguration: marketOrderConfiguration,
            offchainOrdersConfiguration: offchainOrdersConfiguration,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: 1
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "symbol") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.createPerpMarket(params);
    }

    modifier whenLengthOfSymbolIsNotZero() {
        _;
    }

    function test_RevertWhen_PriceAdapterIsZero()
        external
        whenMarketIdIsNotZero
        whenLengthOfNameIsNotZero
        whenLengthOfSymbolIsNotZero
    {
        SettlementConfiguration.Data memory offchainOrdersConfiguration;
        SettlementConfiguration.Data memory marketOrderConfiguration;

        GlobalConfigurationBranch.CreatePerpMarketParams memory params = GlobalConfigurationBranch
            .CreatePerpMarketParams({
            marketId: 1,
            name: "BTC/USD",
            symbol: "BTC",
            priceAdapter: address(0),
            initialMarginRateX18: 2,
            maintenanceMarginRateX18: 1,
            maxOpenInterest: 1,
            maxSkew: 1,
            maxFundingVelocity: 1,
            minTradeSizeX18: 1,
            skewScale: 1,
            marketOrderConfiguration: marketOrderConfiguration,
            offchainOrdersConfiguration: offchainOrdersConfiguration,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: 1
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "priceAdapter") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.createPerpMarket(params);
    }

    modifier whenPriceAdapterIsNotZero() {
        _;
    }

    function test_RevertWhen_MaintenanceMarginRateIsZero()
        external
        whenMarketIdIsNotZero
        whenLengthOfNameIsNotZero
        whenLengthOfSymbolIsNotZero
        whenPriceAdapterIsNotZero
    {
        SettlementConfiguration.Data memory offchainOrdersConfiguration;
        SettlementConfiguration.Data memory marketOrderConfiguration;

        GlobalConfigurationBranch.CreatePerpMarketParams memory params = GlobalConfigurationBranch
            .CreatePerpMarketParams({
            marketId: 1,
            name: "BTC/USD",
            symbol: "BTC",
            priceAdapter: address(0x20),
            initialMarginRateX18: 2,
            maintenanceMarginRateX18: 0,
            maxOpenInterest: 1,
            maxSkew: 1,
            maxFundingVelocity: 1,
            minTradeSizeX18: 1,
            skewScale: 1,
            marketOrderConfiguration: marketOrderConfiguration,
            offchainOrdersConfiguration: offchainOrdersConfiguration,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: 1
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "maintenanceMarginRateX18") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.createPerpMarket(params);
    }

    modifier whenMaintenanceMarginRateIsNotZero() {
        _;
    }

    function test_RevertWhen_MaxOpenInterestIsZero()
        external
        whenMarketIdIsNotZero
        whenLengthOfNameIsNotZero
        whenLengthOfSymbolIsNotZero
        whenPriceAdapterIsNotZero
        whenMaintenanceMarginRateIsNotZero
    {
        SettlementConfiguration.Data memory offchainOrdersConfiguration;
        SettlementConfiguration.Data memory marketOrderConfiguration;

        GlobalConfigurationBranch.CreatePerpMarketParams memory params = GlobalConfigurationBranch
            .CreatePerpMarketParams({
            marketId: 1,
            name: "BTC/USD",
            symbol: "BTC",
            priceAdapter: address(0x20),
            initialMarginRateX18: 2,
            maintenanceMarginRateX18: 1,
            maxOpenInterest: 0,
            maxSkew: 1,
            maxFundingVelocity: 1,
            minTradeSizeX18: 1,
            skewScale: 1,
            marketOrderConfiguration: marketOrderConfiguration,
            offchainOrdersConfiguration: offchainOrdersConfiguration,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: 1
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "maxOpenInterest") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.createPerpMarket(params);
    }

    modifier whenMaxOpenInterestIsNotZero() {
        _;
    }

    function test_RevertWhen_MaxSkewIsZero()
        external
        whenMarketIdIsNotZero
        whenLengthOfNameIsNotZero
        whenLengthOfSymbolIsNotZero
        whenPriceAdapterIsNotZero
        whenMaintenanceMarginRateIsNotZero
        whenMaxOpenInterestIsNotZero
    {
        SettlementConfiguration.Data memory offchainOrdersConfiguration;
        SettlementConfiguration.Data memory marketOrderConfiguration;

        GlobalConfigurationBranch.CreatePerpMarketParams memory params = GlobalConfigurationBranch
            .CreatePerpMarketParams({
            marketId: 1,
            name: "BTC/USD",
            symbol: "BTC",
            priceAdapter: address(0x20),
            initialMarginRateX18: 2,
            maintenanceMarginRateX18: 1,
            maxOpenInterest: 1,
            maxSkew: 0,
            maxFundingVelocity: 1,
            minTradeSizeX18: 1,
            skewScale: 1,
            marketOrderConfiguration: marketOrderConfiguration,
            offchainOrdersConfiguration: offchainOrdersConfiguration,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: 1
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "maxSkew") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.createPerpMarket(params);
    }

    modifier whenMaxSkewIsNotZero() {
        _;
    }

    function test_RevertWhen_InitialMarginRateIsLessOrEqualToMaintenanceMargin()
        external
        whenMarketIdIsNotZero
        whenLengthOfNameIsNotZero
        whenLengthOfSymbolIsNotZero
        whenPriceAdapterIsNotZero
        whenMaintenanceMarginRateIsNotZero
        whenMaxOpenInterestIsNotZero
        whenMaxSkewIsNotZero
    {
        SettlementConfiguration.Data memory offchainOrdersConfiguration;
        SettlementConfiguration.Data memory marketOrderConfiguration;

        GlobalConfigurationBranch.CreatePerpMarketParams memory params = GlobalConfigurationBranch
            .CreatePerpMarketParams({
            marketId: 1,
            name: "BTC/USD",
            symbol: "BTC",
            priceAdapter: address(0x20),
            initialMarginRateX18: 1,
            maintenanceMarginRateX18: 1,
            maxOpenInterest: 1,
            maxSkew: 1,
            maxFundingVelocity: 1,
            minTradeSizeX18: 1,
            skewScale: 1,
            marketOrderConfiguration: marketOrderConfiguration,
            offchainOrdersConfiguration: offchainOrdersConfiguration,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: 1
        });

        // it should revert
        vm.expectRevert({ revertData: Errors.InitialMarginRateLessOrEqualThanMaintenanceMarginRate.selector });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.createPerpMarket(params);
    }

    modifier whenInitialMarginIsNotLessOrEqualToMaintenanceMargin() {
        _;
    }

    function test_RevertWhen_SkewScaleIsZero()
        external
        whenMarketIdIsNotZero
        whenLengthOfNameIsNotZero
        whenLengthOfSymbolIsNotZero
        whenPriceAdapterIsNotZero
        whenMaintenanceMarginRateIsNotZero
        whenMaxOpenInterestIsNotZero
        whenMaxSkewIsNotZero
        whenInitialMarginIsNotLessOrEqualToMaintenanceMargin
    {
        SettlementConfiguration.Data memory offchainOrdersConfiguration;
        SettlementConfiguration.Data memory marketOrderConfiguration;

        GlobalConfigurationBranch.CreatePerpMarketParams memory params = GlobalConfigurationBranch
            .CreatePerpMarketParams({
            marketId: 1,
            name: "BTC/USD",
            symbol: "BTC",
            priceAdapter: address(0x20),
            initialMarginRateX18: 2,
            maintenanceMarginRateX18: 1,
            maxOpenInterest: 1,
            maxSkew: 1,
            maxFundingVelocity: 1,
            minTradeSizeX18: 1,
            skewScale: 0,
            marketOrderConfiguration: marketOrderConfiguration,
            offchainOrdersConfiguration: offchainOrdersConfiguration,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: 1
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "skewScale") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.createPerpMarket(params);
    }

    modifier whenSkewScaleIsNotZero() {
        _;
    }

    function test_RevertWhen_MinTradeSizeIsZero()
        external
        whenMarketIdIsNotZero
        whenLengthOfNameIsNotZero
        whenLengthOfSymbolIsNotZero
        whenPriceAdapterIsNotZero
        whenMaintenanceMarginRateIsNotZero
        whenMaxOpenInterestIsNotZero
        whenMaxSkewIsNotZero
        whenInitialMarginIsNotLessOrEqualToMaintenanceMargin
        whenSkewScaleIsNotZero
    {
        SettlementConfiguration.Data memory offchainOrdersConfiguration;
        SettlementConfiguration.Data memory marketOrderConfiguration;

        GlobalConfigurationBranch.CreatePerpMarketParams memory params = GlobalConfigurationBranch
            .CreatePerpMarketParams({
            marketId: 1,
            name: "BTC/USD",
            symbol: "BTC",
            priceAdapter: address(0x20),
            initialMarginRateX18: 2,
            maintenanceMarginRateX18: 1,
            maxOpenInterest: 1,
            maxSkew: 1,
            maxFundingVelocity: 1,
            minTradeSizeX18: 0,
            skewScale: 1,
            marketOrderConfiguration: marketOrderConfiguration,
            offchainOrdersConfiguration: offchainOrdersConfiguration,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: 1
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "minTradeSizeX18") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.createPerpMarket(params);
    }

    modifier whenMinTradeSizeIsNotZero() {
        _;
    }

    function test_RevertWhen_MaxFundingVelocityIsZero()
        external
        whenMarketIdIsNotZero
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
        SettlementConfiguration.Data memory offchainOrdersConfiguration;
        SettlementConfiguration.Data memory marketOrderConfiguration;

        GlobalConfigurationBranch.CreatePerpMarketParams memory params = GlobalConfigurationBranch
            .CreatePerpMarketParams({
            marketId: 1,
            name: "BTC/USD",
            symbol: "BTC",
            priceAdapter: address(0x20),
            initialMarginRateX18: 2,
            maintenanceMarginRateX18: 1,
            maxOpenInterest: 1,
            maxSkew: 1,
            maxFundingVelocity: 0,
            minTradeSizeX18: 1,
            skewScale: 1,
            marketOrderConfiguration: marketOrderConfiguration,
            offchainOrdersConfiguration: offchainOrdersConfiguration,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: 1
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "maxFundingVelocity") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.createPerpMarket(params);
    }

    modifier whenMaxFundingVelocityIsNotZero() {
        _;
    }

    function test_RevertWhen_PriceFeedHeartbeatSecondsIsZero()
        external
        whenMarketIdIsNotZero
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
        SettlementConfiguration.Data memory offchainOrdersConfiguration;
        SettlementConfiguration.Data memory marketOrderConfiguration;

        GlobalConfigurationBranch.CreatePerpMarketParams memory params = GlobalConfigurationBranch
            .CreatePerpMarketParams({
            marketId: 1,
            name: "BTC/USD",
            symbol: "BTC",
            priceAdapter: address(0x20),
            initialMarginRateX18: 2,
            maintenanceMarginRateX18: 1,
            maxOpenInterest: 1,
            maxSkew: 1,
            maxFundingVelocity: 1,
            minTradeSizeX18: 1,
            skewScale: 1,
            marketOrderConfiguration: marketOrderConfiguration,
            offchainOrdersConfiguration: offchainOrdersConfiguration,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: 0
        });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "priceFeedHeartbeatSeconds") });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.createPerpMarket(params);
    }

    function test_WhenPriceFeedHearbeatSecondsIsNotZero()
        external
        whenMarketIdIsNotZero
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
        changePrank({ msgSender: users.owner.account });

        SettlementConfiguration.Data memory offchainOrdersConfiguration;
        SettlementConfiguration.Data memory marketOrderConfiguration;

        GlobalConfigurationBranch.CreatePerpMarketParams memory params = GlobalConfigurationBranch
            .CreatePerpMarketParams({
            marketId: 1,
            name: "BTC/USD",
            symbol: "BTC",
            priceAdapter: address(0x20),
            initialMarginRateX18: 2,
            maintenanceMarginRateX18: 1,
            maxOpenInterest: 1,
            maxSkew: 1,
            maxFundingVelocity: 1,
            minTradeSizeX18: 1,
            skewScale: 1,
            marketOrderConfiguration: marketOrderConfiguration,
            offchainOrdersConfiguration: offchainOrdersConfiguration,
            orderFees: OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 }),
            priceFeedHeartbeatSeconds: 1
        });

        // it should emit {LogCreatePerpMarket} event
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit GlobalConfigurationBranch.LogCreatePerpMarket(users.owner.account, params.marketId);

        // it should create perp market
        // it should enable perp market
        perpsEngine.createPerpMarket({ params: params });
    }
}
