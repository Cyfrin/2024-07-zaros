// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { OrderFees } from "@zaros/perpetuals/leaves/OrderFees.sol";
import { MockPriceFeed } from "../../test/mocks/MockPriceFeed.sol";
import { MarketOrderKeeper } from "@zaros/external/chainlink/keepers/market-order/MarketOrderKeeper.sol";
import { IPerpsEngine } from "@zaros/perpetuals/PerpsEngine.sol";
import { SettlementConfiguration } from "@zaros/perpetuals/leaves/SettlementConfiguration.sol";
import { IVerifierProxy } from "@zaros/external/chainlink/interfaces/IVerifierProxy.sol";
import { GlobalConfigurationBranch } from "@zaros/perpetuals/branches/GlobalConfigurationBranch.sol";

// Open Zeppelin dependencies
import { ERC1967Proxy } from "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

// Forge dependencies
import { StdCheats, StdUtils } from "forge-std/Test.sol";

// Markets
import { BtcUsd } from "./BtcUsd.sol";
import { EthUsd } from "./EthUsd.sol";
import { LinkUsd } from "./LinkUsd.sol";
import { ArbUsd } from "./ArbUsd.sol";
import { BnbUsd } from "./BnbUsd.sol";
import { DogeUsd } from "./DogeUsd.sol";
import { SolUsd } from "./SolUsd.sol";
import { MaticUsd } from "./MaticUsd.sol";
import { LtcUsd } from "./LtcUsd.sol";
import { FtmUsd } from "./FtmUsd.sol";

abstract contract Markets is
    StdCheats,
    StdUtils,
    BtcUsd,
    EthUsd,
    LinkUsd,
    ArbUsd,
    BnbUsd,
    DogeUsd,
    SolUsd,
    MaticUsd,
    LtcUsd,
    FtmUsd
{
    struct MarketConfig {
        uint128 marketId;
        string marketName;
        string marketSymbol;
        uint128 imr;
        uint128 mmr;
        uint128 marginRequirements;
        uint128 maxOi;
        uint128 maxSkew;
        uint128 maxFundingVelocity;
        uint128 minTradeSize;
        uint256 skewScale;
        address priceAdapter;
        bytes32 streamId;
        string streamIdString;
        OrderFees.Data orderFees;
        uint256 mockUsdPrice;
        uint32 priceFeedHeartbeatSeconds;
    }

    /// @notice Market configurations mapped by market id.
    mapping(uint256 marketId => MarketConfig marketConfig) internal marketsConfig;
    /// @notice Market order keepers contracts mapped by market id.
    mapping(uint256 marketId => address keeper) internal marketOrderKeepers;

    // TODO: Update to actual offchain orders keeper address
    /// @notice The address responsible by filling the offchain created offchain orders.
    address internal constant OFFCHAIN_ORDERS_KEEPER_ADDRESS = 0xeA6930f85b5F52507AbE7B2c5aF1153391BEb2b8;
    /// @notice General perps engine system configuration parameters.
    string internal constant DATA_STREAMS_FEED_PARAM_KEY = "feedIDs";
    string internal constant DATA_STREAMS_TIME_PARAM_KEY = "timestamp";
    uint80 internal constant DEFAULT_SETTLEMENT_FEE = 2e18;

    function setupMarketsConfig() internal {
        marketsConfig[BTC_USD_MARKET_ID] = MarketConfig({
            marketId: BTC_USD_MARKET_ID,
            marketName: BTC_USD_MARKET_NAME,
            marketSymbol: BTC_USD_MARKET_SYMBOL,
            imr: BTC_USD_IMR,
            mmr: BTC_USD_MMR,
            marginRequirements: BTC_USD_MARGIN_REQUIREMENTS,
            maxOi: BTC_USD_MAX_OI,
            maxSkew: BTC_USD_MAX_SKEW,
            skewScale: BTC_USD_SKEW_SCALE,
            minTradeSize: BTC_USD_MIN_TRADE_SIZE,
            maxFundingVelocity: BTC_USD_MAX_FUNDING_VELOCITY,
            priceAdapter: BTC_USD_PRICE_FEED,
            streamId: BTC_USD_STREAM_ID,
            streamIdString: STRING_BTC_USD_STREAM_ID,
            orderFees: btcUsdOrderFees,
            mockUsdPrice: MOCK_BTC_USD_PRICE,
            priceFeedHeartbeatSeconds: BTC_USD_PRICE_FEED_HEARTBEATS_SECONDS
        });

        marketsConfig[ETH_USD_MARKET_ID] = MarketConfig({
            marketId: ETH_USD_MARKET_ID,
            marketName: ETH_USD_MARKET_NAME,
            marketSymbol: ETH_USD_MARKET_SYMBOL,
            imr: ETH_USD_IMR,
            mmr: ETH_USD_MMR,
            marginRequirements: ETH_USD_MARGIN_REQUIREMENTS,
            maxOi: ETH_USD_MAX_OI,
            maxSkew: ETH_USD_MAX_SKEW,
            skewScale: ETH_USD_SKEW_SCALE,
            minTradeSize: ETH_USD_MIN_TRADE_SIZE,
            maxFundingVelocity: ETH_USD_MAX_FUNDING_VELOCITY,
            priceAdapter: ETH_USD_PRICE_FEED,
            streamId: ETH_USD_STREAM_ID,
            streamIdString: STRING_ETH_USD_STREAM_ID,
            orderFees: ethUsdOrderFees,
            mockUsdPrice: MOCK_ETH_USD_PRICE,
            priceFeedHeartbeatSeconds: ETH_USD_PRICE_FEED_HEARTBEATS_SECONDS
        });

        marketsConfig[LINK_USD_MARKET_ID] = MarketConfig({
            marketId: LINK_USD_MARKET_ID,
            marketName: LINK_USD_MARKET_NAME,
            marketSymbol: LINK_USD_MARKET_SYMBOL,
            imr: LINK_USD_IMR,
            mmr: LINK_USD_MMR,
            marginRequirements: LINK_USD_MARGIN_REQUIREMENTS,
            maxOi: LINK_USD_MAX_OI,
            maxSkew: LINK_USD_MAX_SKEW,
            skewScale: LINK_USD_SKEW_SCALE,
            minTradeSize: LINK_USD_MIN_TRADE_SIZE,
            maxFundingVelocity: LINK_USD_MAX_FUNDING_VELOCITY,
            priceAdapter: LINK_USD_PRICE_FEED,
            streamId: LINK_USD_STREAM_ID,
            streamIdString: STRING_LINK_USD_STREAM_ID,
            orderFees: linkUsdOrderFees,
            mockUsdPrice: MOCK_LINK_USD_PRICE,
            priceFeedHeartbeatSeconds: LINK_USD_PRICE_FEED_HEARTBEATS_SECONDS
        });

        marketsConfig[ARB_USD_MARKET_ID] = MarketConfig({
            marketId: ARB_USD_MARKET_ID,
            marketName: ARB_USD_MARKET_NAME,
            marketSymbol: ARB_USD_MARKET_SYMBOL,
            imr: ARB_USD_IMR,
            mmr: ARB_USD_MMR,
            marginRequirements: ARB_USD_MARGIN_REQUIREMENTS,
            maxOi: ARB_USD_MAX_OI,
            maxSkew: ARB_USD_MAX_SKEW,
            skewScale: ARB_USD_SKEW_SCALE,
            minTradeSize: ARB_USD_MIN_TRADE_SIZE,
            maxFundingVelocity: ARB_USD_MAX_FUNDING_VELOCITY,
            priceAdapter: ARB_USD_PRICE_FEED,
            streamId: ARB_USD_STREAM_ID,
            streamIdString: STRING_ARB_USD_STREAM_ID,
            orderFees: arbUsdOrderFees,
            mockUsdPrice: MOCK_ARB_USD_PRICE,
            priceFeedHeartbeatSeconds: ARB_USD_PRICE_FEED_HEARTBEATS_SECONDS
        });

        marketsConfig[BNB_USD_MARKET_ID] = MarketConfig({
            marketId: BNB_USD_MARKET_ID,
            marketName: BNB_USD_MARKET_NAME,
            marketSymbol: BNB_USD_MARKET_SYMBOL,
            imr: BNB_USD_IMR,
            mmr: BNB_USD_MMR,
            marginRequirements: BNB_USD_MARGIN_REQUIREMENTS,
            maxOi: BNB_USD_MAX_OI,
            maxSkew: BNB_USD_MAX_SKEW,
            skewScale: BNB_USD_SKEW_SCALE,
            minTradeSize: BNB_USD_MIN_TRADE_SIZE,
            maxFundingVelocity: BNB_USD_MAX_FUNDING_VELOCITY,
            priceAdapter: BNB_USD_PRICE_FEED,
            streamId: BNB_USD_STREAM_ID,
            streamIdString: STRING_BNB_USD_STREAM_ID,
            orderFees: bnbUsdOrderFees,
            mockUsdPrice: MOCK_BNB_USD_PRICE,
            priceFeedHeartbeatSeconds: BNB_USD_PRICE_FEED_HEARTBEATS_SECONDS
        });

        marketsConfig[DOGE_USD_MARKET_ID] = MarketConfig({
            marketId: DOGE_USD_MARKET_ID,
            marketName: DOGE_USD_MARKET_NAME,
            marketSymbol: DOGE_USD_MARKET_SYMBOL,
            imr: DOGE_USD_IMR,
            mmr: DOGE_USD_MMR,
            marginRequirements: DOGE_USD_MARGIN_REQUIREMENTS,
            maxOi: DOGE_USD_MAX_OI,
            maxSkew: DOGE_USD_MAX_SKEW,
            skewScale: DOGE_USD_SKEW_SCALE,
            minTradeSize: DOGE_USD_MIN_TRADE_SIZE,
            maxFundingVelocity: DOGE_USD_MAX_FUNDING_VELOCITY,
            priceAdapter: DOGE_USD_PRICE_FEED,
            streamId: DOGE_USD_STREAM_ID,
            streamIdString: STRING_DOGE_USD_STREAM_ID,
            orderFees: dogeUsdOrderFees,
            mockUsdPrice: MOCK_DOGE_USD_PRICE,
            priceFeedHeartbeatSeconds: DOGE_USD_PRICE_FEED_HEARTBEATS_SECONDS
        });

        marketsConfig[SOL_USD_MARKET_ID] = MarketConfig({
            marketId: SOL_USD_MARKET_ID,
            marketName: SOL_USD_MARKET_NAME,
            marketSymbol: SOL_USD_MARKET_SYMBOL,
            imr: SOL_USD_IMR,
            mmr: SOL_USD_MMR,
            marginRequirements: SOL_USD_MARGIN_REQUIREMENTS,
            maxOi: SOL_USD_MAX_OI,
            maxSkew: SOL_USD_MAX_SKEW,
            skewScale: SOL_USD_SKEW_SCALE,
            minTradeSize: SOL_USD_MIN_TRADE_SIZE,
            maxFundingVelocity: SOL_USD_MAX_FUNDING_VELOCITY,
            priceAdapter: SOL_USD_PRICE_FEED,
            streamId: SOL_USD_STREAM_ID,
            streamIdString: STRING_SOL_USD_STREAM_ID,
            orderFees: solUsdOrderFees,
            mockUsdPrice: MOCK_SOL_USD_PRICE,
            priceFeedHeartbeatSeconds: SOL_USD_PRICE_FEED_HEARTBEATS_SECONDS
        });

        marketsConfig[MATIC_USD_MARKET_ID] = MarketConfig({
            marketId: MATIC_USD_MARKET_ID,
            marketName: MATIC_USD_MARKET_NAME,
            marketSymbol: MATIC_USD_MARKET_SYMBOL,
            imr: MATIC_USD_IMR,
            mmr: MATIC_USD_MMR,
            marginRequirements: MATIC_USD_MARGIN_REQUIREMENTS,
            maxOi: MATIC_USD_MAX_OI,
            maxSkew: MATIC_USD_MAX_SKEW,
            skewScale: MATIC_USD_SKEW_SCALE,
            minTradeSize: MATIC_USD_MIN_TRADE_SIZE,
            maxFundingVelocity: MATIC_USD_MAX_FUNDING_VELOCITY,
            priceAdapter: MATIC_USD_PRICE_FEED,
            streamId: MATIC_USD_STREAM_ID,
            streamIdString: STRING_MATIC_USD_STREAM_ID,
            orderFees: maticUsdOrderFees,
            mockUsdPrice: MOCK_MATIC_USD_PRICE,
            priceFeedHeartbeatSeconds: MATIC_USD_PRICE_FEED_HEARTBEATS_SECONDS
        });

        marketsConfig[LTC_USD_MARKET_ID] = MarketConfig({
            marketId: LTC_USD_MARKET_ID,
            marketName: LTC_USD_MARKET_NAME,
            marketSymbol: LTC_USD_MARKET_SYMBOL,
            imr: LTC_USD_IMR,
            mmr: LTC_USD_MMR,
            marginRequirements: LTC_USD_MARGIN_REQUIREMENTS,
            maxOi: LTC_USD_MAX_OI,
            maxSkew: LTC_USD_MAX_SKEW,
            skewScale: LTC_USD_SKEW_SCALE,
            minTradeSize: LTC_USD_MIN_TRADE_SIZE,
            maxFundingVelocity: LTC_USD_MAX_FUNDING_VELOCITY,
            priceAdapter: LTC_USD_PRICE_FEED,
            streamId: LTC_USD_STREAM_ID,
            streamIdString: STRING_LTC_USD_STREAM_ID,
            orderFees: ltcUsdOrderFees,
            mockUsdPrice: MOCK_LTC_USD_PRICE,
            priceFeedHeartbeatSeconds: LTC_USD_PRICE_FEED_HEARTBEATS_SECONDS
        });

        marketsConfig[FTM_USD_MARKET_ID] = MarketConfig({
            marketId: FTM_USD_MARKET_ID,
            marketName: FTM_USD_MARKET_NAME,
            marketSymbol: FTM_USD_MARKET_SYMBOL,
            imr: FTM_USD_IMR,
            mmr: FTM_USD_MMR,
            marginRequirements: FTM_USD_MARGIN_REQUIREMENTS,
            maxOi: FTM_USD_MAX_OI,
            maxSkew: FTM_USD_MAX_SKEW,
            skewScale: FTM_USD_SKEW_SCALE,
            minTradeSize: FTM_USD_MIN_TRADE_SIZE,
            maxFundingVelocity: FTM_USD_MAX_FUNDING_VELOCITY,
            priceAdapter: FTM_USD_PRICE_FEED,
            streamId: FTM_USD_STREAM_ID,
            streamIdString: STRING_FTM_USD_STREAM_ID,
            orderFees: ftmUsdOrderFees,
            mockUsdPrice: MOCK_FTM_USD_PRICE,
            priceFeedHeartbeatSeconds: FTM_USD_PRICE_FEED_HEARTBEATS_SECONDS
        });
    }

    function getFilteredMarketsConfig(uint256[2] memory marketsIdsRange)
        internal
        view
        returns (MarketConfig[] memory)
    {
        uint256 initialMarketId = marketsIdsRange[0];
        uint256 finalMarketId = marketsIdsRange[1];
        uint256 filteredMarketsLength = finalMarketId - initialMarketId + 1;

        MarketConfig[] memory filteredMarketsConfig = new MarketConfig[](filteredMarketsLength);

        uint256 nextMarketId = initialMarketId;
        for (uint256 i; i < filteredMarketsLength; i++) {
            filteredMarketsConfig[i] = marketsConfig[nextMarketId];
            nextMarketId++;
        }

        return filteredMarketsConfig;
    }

    function createPerpMarkets(
        address deployer,
        IPerpsEngine perpsEngine,
        uint256 initialMarketId,
        uint256 finalMarketId,
        IVerifierProxy chainlinkVerifier,
        bool isTest
    )
        public
    {
        for (uint256 i = initialMarketId; i <= finalMarketId; i++) {
            address marketOrderKeeperImplementation = address(new MarketOrderKeeper());
            address marketOrderKeeper = deployMarketOrderKeeper(
                marketsConfig[i].marketId, deployer, perpsEngine, marketOrderKeeperImplementation
            );

            SettlementConfiguration.DataStreamsStrategy memory settlementConfigurationData = SettlementConfiguration
                .DataStreamsStrategy({ chainlinkVerifier: chainlinkVerifier, streamId: marketsConfig[i].streamId });

            SettlementConfiguration.Data memory marketOrderConfiguration = SettlementConfiguration.Data({
                strategy: SettlementConfiguration.Strategy.DATA_STREAMS_DEFAULT,
                isEnabled: true,
                fee: DEFAULT_SETTLEMENT_FEE,
                keeper: marketOrderKeeper,
                data: abi.encode(settlementConfigurationData)
            });

            SettlementConfiguration.Data memory offchainOrdersConfiguration = SettlementConfiguration.Data({
                strategy: SettlementConfiguration.Strategy.DATA_STREAMS_DEFAULT,
                isEnabled: true,
                fee: DEFAULT_SETTLEMENT_FEE,
                keeper: OFFCHAIN_ORDERS_KEEPER_ADDRESS,
                data: abi.encode(settlementConfigurationData)
            });

            // update stored price adapter at tests
            address priceAdapter = isTest
                ? address(new MockPriceFeed(18, int256(marketsConfig[i].mockUsdPrice)))
                : marketsConfig[i].priceAdapter;

            marketsConfig[i].priceAdapter = priceAdapter;

            perpsEngine.createPerpMarket(
                GlobalConfigurationBranch.CreatePerpMarketParams({
                    marketId: marketsConfig[i].marketId,
                    name: marketsConfig[i].marketName,
                    symbol: marketsConfig[i].marketSymbol,
                    priceAdapter: priceAdapter,
                    initialMarginRateX18: marketsConfig[i].imr,
                    maintenanceMarginRateX18: marketsConfig[i].mmr,
                    maxOpenInterest: marketsConfig[i].maxOi,
                    maxSkew: marketsConfig[i].maxSkew,
                    maxFundingVelocity: marketsConfig[i].maxFundingVelocity,
                    minTradeSizeX18: marketsConfig[i].minTradeSize,
                    skewScale: marketsConfig[i].skewScale,
                    marketOrderConfiguration: marketOrderConfiguration,
                    offchainOrdersConfiguration: offchainOrdersConfiguration,
                    orderFees: marketsConfig[i].orderFees,
                    priceFeedHeartbeatSeconds: marketsConfig[i].priceFeedHeartbeatSeconds
                })
            );
        }
    }

    function deployMarketOrderKeeper(
        uint128 marketId,
        address deployer,
        IPerpsEngine perpsEngine,
        address marketOrderKeeperImplementation
    )
        internal
        returns (address marketOrderKeeper)
    {
        marketOrderKeeper = address(
            new ERC1967Proxy(
                marketOrderKeeperImplementation,
                abi.encodeWithSelector(
                    MarketOrderKeeper.initialize.selector,
                    deployer,
                    perpsEngine,
                    marketId,
                    marketsConfig[marketId].streamIdString
                )
            )
        );

        marketOrderKeepers[marketId] = marketOrderKeeper;
    }
}
