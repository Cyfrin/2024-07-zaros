// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { Errors } from "@zaros/utils/Errors.sol";
import { SettlementConfiguration } from "@zaros/perpetuals/leaves/SettlementConfiguration.sol";
import { SettlementConfigurationHarness } from "test/harnesses/perpetuals/leaves/SettlementConfigurationHarness.sol";

contract SettlementConfiguration_CheckIsSettlementEnabled_Unit_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
    }

    function testFuzz_RevertGiven_TheConfiguredSettlementStrategyIsDisabled(uint256 marketId) external {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        SettlementConfiguration.Data memory newSettlementConfiguration = SettlementConfiguration.Data({
            strategy: SettlementConfiguration.Strategy.DATA_STREAMS_DEFAULT,
            isEnabled: false,
            fee: DEFAULT_SETTLEMENT_FEE,
            keeper: marketOrderKeepers[fuzzMarketConfig.marketId],
            data: bytes("")
        });

        SettlementConfigurationHarness(address(perpsEngine)).exposed_update(
            fuzzMarketConfig.marketId,
            SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
            newSettlementConfiguration
        );

        // it should revert
        vm.expectRevert({ revertData: Errors.SettlementDisabled.selector });
        // TODO: bound settlement configuration ids from the market order configuration id, up to the higher id
        // available once offchain orders are implemented
        SettlementConfigurationHarness(address(perpsEngine)).exposed_checkIsSettlementEnabled(
            fuzzMarketConfig.marketId, SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID
        );
    }

    function testFuzz_GivenTheConfiguredSettlementStrategyIsEnabled(uint256 marketId) external view {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        // it should pass
        SettlementConfigurationHarness(address(perpsEngine)).exposed_checkIsSettlementEnabled(
            fuzzMarketConfig.marketId, SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID
        );
    }
}
