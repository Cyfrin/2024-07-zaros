// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { IVerifierProxy } from "@zaros/external/chainlink/interfaces/IVerifierProxy.sol";
import { MarketOrderKeeper } from "@zaros/external/chainlink/keepers/market-order/MarketOrderKeeper.sol";
import { IPerpsEngine } from "@zaros/perpetuals/PerpsEngine.sol";
import { GlobalConfigurationBranch } from "@zaros/perpetuals/branches/GlobalConfigurationBranch.sol";
import { SettlementConfiguration } from "@zaros/perpetuals/leaves/SettlementConfiguration.sol";
import { BaseScript } from "./Base.s.sol";
import { ProtocolConfiguration } from "./utils/ProtocolConfiguration.sol";

// Open Zeppelin dependencies
import { ERC1967Proxy } from "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

// Forge dependencies
import { console } from "forge-std/console.sol";

contract CreatePerpMarkets is BaseScript, ProtocolConfiguration {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/
    IVerifierProxy internal chainlinkVerifier;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/
    IPerpsEngine internal perpsEngine;

    function run(uint256 initialMarketId, uint256 finalMarketId) public broadcaster {
        perpsEngine = IPerpsEngine(payable(address(vm.envAddress("PERPS_ENGINE"))));
        chainlinkVerifier = IVerifierProxy(vm.envAddress("CHAINLINK_VERIFIER"));

        uint256[2] memory marketsIdsRange;
        marketsIdsRange[0] = initialMarketId;
        marketsIdsRange[1] = finalMarketId;

        setupMarketsConfig();

        MarketConfig[] memory filteredMarketsConfig = getFilteredMarketsConfig(marketsIdsRange);

        address marketOrderKeeperImplementation = address(new MarketOrderKeeper());
        console.log("MarketOrderKeeper Implementation: ", marketOrderKeeperImplementation);

        for (uint256 i; i < filteredMarketsConfig.length; i++) {
            SettlementConfiguration.DataStreamsStrategy memory orderConfigurationData = SettlementConfiguration
                .DataStreamsStrategy({ chainlinkVerifier: chainlinkVerifier, streamId: filteredMarketsConfig[i].streamId });

            address marketOrderKeeper = deployMarketOrderKeeper(
                filteredMarketsConfig[i].marketId, deployer, perpsEngine, marketOrderKeeperImplementation
            );

            console.log(
                "Market Order Keeper Deployed: Market ID: ",
                filteredMarketsConfig[i].marketId,
                " Keeper Address: ",
                marketOrderKeeper
            );

            SettlementConfiguration.Data memory marketOrderConfiguration = SettlementConfiguration.Data({
                strategy: SettlementConfiguration.Strategy.DATA_STREAMS_DEFAULT,
                isEnabled: true,
                fee: DEFAULT_SETTLEMENT_FEE,
                keeper: marketOrderKeeper,
                data: abi.encode(orderConfigurationData)
            });

            SettlementConfiguration.Data memory offchainOrdersConfiguration = SettlementConfiguration.Data({
                strategy: SettlementConfiguration.Strategy.DATA_STREAMS_DEFAULT,
                isEnabled: true,
                fee: DEFAULT_SETTLEMENT_FEE,
                keeper: OFFCHAIN_ORDERS_KEEPER_ADDRESS,
                data: abi.encode(orderConfigurationData)
            });

            perpsEngine.createPerpMarket({
                params: GlobalConfigurationBranch.CreatePerpMarketParams({
                    marketId: filteredMarketsConfig[i].marketId,
                    name: filteredMarketsConfig[i].marketName,
                    symbol: filteredMarketsConfig[i].marketSymbol,
                    priceAdapter: filteredMarketsConfig[i].priceAdapter,
                    initialMarginRateX18: filteredMarketsConfig[i].imr,
                    maintenanceMarginRateX18: filteredMarketsConfig[i].mmr,
                    maxOpenInterest: filteredMarketsConfig[i].maxOi,
                    maxSkew: filteredMarketsConfig[i].maxSkew,
                    maxFundingVelocity: filteredMarketsConfig[i].maxFundingVelocity,
                    minTradeSizeX18: filteredMarketsConfig[i].minTradeSize,
                    skewScale: filteredMarketsConfig[i].skewScale,
                    marketOrderConfiguration: marketOrderConfiguration,
                    offchainOrdersConfiguration: offchainOrdersConfiguration,
                    orderFees: filteredMarketsConfig[i].orderFees,
                    priceFeedHeartbeatSeconds: filteredMarketsConfig[i].priceFeedHeartbeatSeconds
                })
            });
        }
    }

    function deployMarketOrderKeeper(
        uint128 marketId,
        string memory streamIdString,
        address marketOrderKeeperImplementation
    )
        internal
        returns (address marketOrderKeeper)
    {
        marketOrderKeeper = address(
            new ERC1967Proxy(
                marketOrderKeeperImplementation,
                abi.encodeWithSelector(
                    MarketOrderKeeper.initialize.selector, deployer, perpsEngine, marketId, streamIdString
                )
            )
        );
    }
}
