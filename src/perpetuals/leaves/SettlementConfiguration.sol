// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { PremiumReport } from "@zaros/external/chainlink/interfaces/IStreamsLookupCompatible.sol";
import { IVerifierProxy } from "@zaros/external/chainlink/interfaces/IVerifierProxy.sol";
import { FeeAsset } from "@zaros/external/chainlink/interfaces/IFeeManager.sol";
import { ChainlinkUtil } from "@zaros/external/chainlink/ChainlinkUtil.sol";
import { Errors } from "@zaros/utils/Errors.sol";
import { ChainlinkUtil } from "@zaros/external/chainlink/ChainlinkUtil.sol";

// Open Zeppelin dependencies
import { SafeCast } from "@openzeppelin/utils/math/SafeCast.sol";

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";

/// @notice Settlement strategies supported by the protocol.
library SettlementConfiguration {
    using SafeCast for int256;

    /// @notice ERC7201 storage location.
    bytes32 internal constant SETTLEMENT_CONFIGURATION_LOCATION = keccak256(
        abi.encode(uint256(keccak256("fi.zaros.perpetuals.SettlementConfiguration")) - 1)
    ) & ~bytes32(uint256(0xff));
    /// @notice The default strategy id for a given market's onchain market orders settlementConfiguration.
    uint128 internal constant MARKET_ORDER_CONFIGURATION_ID = 0;
    /// @notice The default strategy id for a given market's offchain orders settlementConfiguration.
    uint128 internal constant OFFCHAIN_ORDERS_CONFIGURATION_ID = 1;

    /// @notice Supported settlement strategies.
    /// @param DATA_STREAMS_DEFAULT The strategy id that uses default Chainlink Data Streams feeds to settle orders.
    /// @dev In the future we'll support RWA feeds and other types of settlement strategies.
    enum Strategy {
        DATA_STREAMS_DEFAULT
    }

    /// @notice {SettlementConfiguration} namespace storage structure.
    /// @param strategy The strategy id active.
    /// @param isEnabled Whether the strategy is enabled or not. May be used to pause trading in a market.
    /// @param fee The settlement cost in USD charged from the trader.
    /// @param keeper The address of the keeper that executes trades.
    /// @param data Data structure required for the settlement configuration, varies for each settlementConfiguration.
    struct Data {
        Strategy strategy;
        bool isEnabled;
        uint80 fee;
        address keeper;
        bytes data;
    }

    /// @notice Data structure used by CL Data Streams powered orders.
    /// @param chainlinkVerifier The Chainlink Verifier contract address.
    /// @param streamId The Chainlink Data Streams stream id.
    /// @param feedLabel The Chainlink Data Streams feed label.
    /// @param queryLabel The Chainlink Data Streams query label.
    struct DataStreamsStrategy {
        IVerifierProxy chainlinkVerifier;
        bytes32 streamId;
    }

    function load(
        uint128 marketId,
        uint128 settlementConfigurationId
    )
        internal
        pure
        returns (Data storage settlementConfiguration)
    {
        bytes32 slot = keccak256(abi.encode(SETTLEMENT_CONFIGURATION_LOCATION, marketId, settlementConfigurationId));
        assembly {
            settlementConfiguration.slot := slot
        }
    }

    /// @notice Checks if the configured settlement strategy is enabled to proceed with execution.
    /// @param self The {SettlementConfiguration} storage pointer.
    function checkIsSettlementEnabled(Data storage self) internal view {
        if (!self.isEnabled) {
            revert Errors.SettlementDisabled();
        }
    }

    /// @notice Checks if the provided data streams report is using the expected stream id.
    /// @param streamId The expected stream id.
    /// @param verifiedReportData The verified report data.
    function requireDataStreamsReportIsValid(
        bytes32 streamId,
        bytes memory verifiedReportData,
        uint256 maxVerificationDelay
    )
        internal
        view
    {
        PremiumReport memory premiumReport = abi.decode(verifiedReportData, (PremiumReport));

        if (
            streamId != premiumReport.feedId
                || block.timestamp > premiumReport.validFromTimestamp + maxVerificationDelay
        ) {
            revert Errors.InvalidDataStreamReport(streamId, premiumReport.feedId);
        }
    }

    /// @notice Updates the settlement configuration of a given market.
    /// @param marketId The market id.
    /// @param settlementConfigurationId The settlement configuration id.
    /// @param settlementConfiguration The new settlement configuration.
    function update(
        uint128 marketId,
        uint128 settlementConfigurationId,
        Data memory settlementConfiguration
    )
        internal
    {
        Data storage self = load(marketId, settlementConfigurationId);

        self.strategy = settlementConfiguration.strategy;
        self.isEnabled = settlementConfiguration.isEnabled;
        self.fee = settlementConfiguration.fee;
        self.keeper = settlementConfiguration.keeper;
        self.data = settlementConfiguration.data;
    }

    /// @notice Returns the offchain price for a given order based on the configured strategy and its direction (bid
    /// vs ask).
    /// @dev New settlement strategies may be added in the future, hence the if-else statement.
    /// @param self The {SettlementConfiguration} storage pointer.
    /// @param priceData The unverified price report data.
    /// @param maxVerificationDelay The maximum delay allowed for the off chain price verification.
    /// @return bidX18 The offchain bid price.
    /// @return askX18 The offchain ask price.
    function verifyOffchainPrice(
        Data storage self,
        bytes memory priceData,
        uint256 maxVerificationDelay
    )
        internal
        returns (UD60x18 bidX18, UD60x18 askX18)
    {
        if (self.strategy == Strategy.DATA_STREAMS_DEFAULT) {
            DataStreamsStrategy memory dataStreamsStrategy = abi.decode(self.data, (DataStreamsStrategy));
            bytes memory verifiedPriceData = verifyDataStreamsReport(dataStreamsStrategy, priceData);

            requireDataStreamsReportIsValid(dataStreamsStrategy.streamId, verifiedPriceData, maxVerificationDelay);

            PremiumReport memory premiumReport = abi.decode(verifiedPriceData, (PremiumReport));

            (bidX18, askX18) =
                (ud60x18(int256(premiumReport.bid).toUint256()), ud60x18(int256(premiumReport.ask).toUint256()));
        } else {
            revert Errors.InvalidSettlementStrategy();
        }
    }

    /// @notice Verifies a signed report from Chainlink Data Streams.
    /// @param dataStreamsStrategy The data streams strategy.
    /// @param signedReport The signed report.
    /// @return verifiedReportData The verified report data.
    function verifyDataStreamsReport(
        DataStreamsStrategy memory dataStreamsStrategy,
        bytes memory signedReport
    )
        internal
        returns (bytes memory verifiedReportData)
    {
        IVerifierProxy chainlinkVerifier = dataStreamsStrategy.chainlinkVerifier;

        bytes memory reportData = ChainlinkUtil.getReportData(signedReport);
        (FeeAsset memory fee) = ChainlinkUtil.getEthVericationFee(chainlinkVerifier, reportData);
        verifiedReportData = ChainlinkUtil.verifyReport(chainlinkVerifier, fee, signedReport);
    }
}
