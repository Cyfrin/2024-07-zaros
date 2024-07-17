// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { IVerifierProxy } from "@zaros/external/chainlink/interfaces/IVerifierProxy.sol";
import { SettlementConfiguration } from "@zaros/perpetuals/leaves/SettlementConfiguration.sol";
import { Base_Test } from "test/Base.t.sol";

contract GetSettlementConfiguration_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function testFuzz_GivenSettlementIsConfigured(uint128 marketId) external {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        SettlementConfiguration.Data memory settlementConfiguration = perpsEngine.getSettlementConfiguration(
            fuzzMarketConfig.marketId, SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID
        );

        SettlementConfiguration.DataStreamsStrategy memory expectedMarketOrderConfigurationData =
        SettlementConfiguration.DataStreamsStrategy({
            chainlinkVerifier: IVerifierProxy(mockChainlinkVerifier),
            streamId: marketsConfig[fuzzMarketConfig.marketId].streamId
        });

        SettlementConfiguration.Data memory expectedMarketOrderConfiguration = SettlementConfiguration.Data({
            strategy: SettlementConfiguration.Strategy.DATA_STREAMS_DEFAULT,
            isEnabled: true,
            fee: DEFAULT_SETTLEMENT_FEE,
            keeper: marketOrderKeepers[fuzzMarketConfig.marketId],
            data: abi.encode(expectedMarketOrderConfigurationData)
        });
        // it should return the market's settlement configuration
        assertEq(
            uint8(settlementConfiguration.strategy),
            uint8(expectedMarketOrderConfiguration.strategy),
            "invalid strategy"
        );
        assertEq(settlementConfiguration.isEnabled, expectedMarketOrderConfiguration.isEnabled, "invalid isEnabled");
        assertEq(settlementConfiguration.fee, expectedMarketOrderConfiguration.fee, "invalid fee");
        assertEq(settlementConfiguration.keeper, expectedMarketOrderConfiguration.keeper, "invalid keeper");
        assertEq(settlementConfiguration.data, expectedMarketOrderConfiguration.data, "invalid data");
    }
}
