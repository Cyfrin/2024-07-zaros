// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { SettlementConfiguration } from "@zaros/perpetuals/leaves/TradingAccount.sol";

// PRB Math dependencies
import { UD60x18 } from "@prb-math/UD60x18.sol";

contract SettlementConfigurationHarness {
    function exposed_SettlementConfiguration_load(
        uint128 marketId,
        uint128 settlementConfigurationId
    )
        external
        pure
        returns (SettlementConfiguration.Data memory)
    {
        return SettlementConfiguration.load(marketId, settlementConfigurationId);
    }

    function exposed_checkIsSettlementEnabled(uint128 marketId, uint128 settlementConfigurationId) external view {
        SettlementConfiguration.Data storage self = SettlementConfiguration.load(marketId, settlementConfigurationId);

        SettlementConfiguration.checkIsSettlementEnabled(self);
    }

    function exposed_requireDataStreamsReportIsVaid(
        bytes32 streamId,
        bytes memory verifiedPriceData,
        uint256 maxVerificationDelay
    )
        external
        view
    {
        SettlementConfiguration.requireDataStreamsReportIsValid(streamId, verifiedPriceData, maxVerificationDelay);
    }

    function exposed_update(
        uint128 marketId,
        uint128 settlementConfigurationId,
        SettlementConfiguration.Data memory newSettlementConfiguration
    )
        external
    {
        SettlementConfiguration.update(marketId, settlementConfigurationId, newSettlementConfiguration);
    }

    function exposed_verifyOffchainPrice(
        uint128 marketId,
        uint128 settlementConfigurationId,
        bytes memory priceData,
        uint256 maxVerificationDelay
    )
        external
        returns (UD60x18, UD60x18)
    {
        SettlementConfiguration.Data storage self = SettlementConfiguration.load(marketId, settlementConfigurationId);

        return SettlementConfiguration.verifyOffchainPrice(self, priceData, maxVerificationDelay);
    }

    function exposed_verifyDataStreamsReport(
        SettlementConfiguration.DataStreamsStrategy memory dataStreamsStrategy,
        bytes memory signedReport
    )
        external
        returns (bytes memory)
    {
        return SettlementConfiguration.verifyDataStreamsReport(dataStreamsStrategy, signedReport);
    }
}
