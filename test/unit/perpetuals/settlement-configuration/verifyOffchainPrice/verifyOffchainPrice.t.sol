// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { Errors } from "@zaros/utils/Errors.sol";
import { SettlementConfiguration } from "@zaros/perpetuals/leaves/SettlementConfiguration.sol";
import { SettlementConfigurationHarness } from "test/harnesses/perpetuals/leaves/SettlementConfigurationHarness.sol";
import { IVerifierProxy } from "@zaros/external/chainlink/interfaces/IVerifierProxy.sol";

// PRB Math dependencies
import { UD60x18 } from "@prb-math/UD60x18.sol";

contract SettlementConfiguration_VerifyOffchainPrice_Unit_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
    }

    function testFuzz_RevertWhen_TheStrategyIsDifferentToDataStreamsDefault(
        uint256 marketId,
        uint128 settlementConfigurationId
    )
        external
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        SettlementConfiguration.Data memory newSettlementConfiguration = SettlementConfiguration.Data({
            strategy: SettlementConfiguration.Strategy.DATA_STREAMS_DEFAULT,
            isEnabled: false,
            fee: DEFAULT_SETTLEMENT_FEE,
            keeper: marketOrderKeepers[fuzzMarketConfig.marketId],
            data: bytes("")
        });

        SettlementConfigurationHarness(perpsEngine).exposed_update(
            fuzzMarketConfig.marketId, settlementConfigurationId, newSettlementConfiguration
        );

        // TODO: we need to have more Strategy types to test this

        // it should revert
        // vm.expectRevert({
        //     revertData: abi.encodeWithSelector(Errors.InvalidSettlementStrategy.selector)
        // });

        // perpsEngine.exposed_verifyOffchainPrice(fuzzMarketConfig.marketId, settlementConfigurationId, "",
        // MAX_VERIFICATION_DELAY);
    }

    modifier whenTheStrategyIsEqualToDataStreamsDefault() {
        _;
    }

    function testFuzz_RevertWhen_TheStreamIdFromDataStreamsStrategyIsDifferentToPremiumReportFeedId(
        uint256 marketId,
        uint128 settlementConfigurationId,
        uint256 fuzzStreamId
    )
        external
        whenTheStrategyIsEqualToDataStreamsDefault
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        SettlementConfiguration.DataStreamsStrategy memory dataStreamsStrategy = SettlementConfiguration
            .DataStreamsStrategy({
            chainlinkVerifier: IVerifierProxy(address(mockChainlinkVerifier)),
            streamId: bytes32(fuzzStreamId)
        });

        SettlementConfiguration.Data memory newSettlementConfiguration = SettlementConfiguration.Data({
            strategy: SettlementConfiguration.Strategy.DATA_STREAMS_DEFAULT,
            isEnabled: false,
            fee: DEFAULT_SETTLEMENT_FEE,
            keeper: marketOrderKeepers[fuzzMarketConfig.marketId],
            data: abi.encode(dataStreamsStrategy)
        });

        SettlementConfigurationHarness(perpsEngine).exposed_update(
            fuzzMarketConfig.marketId, settlementConfigurationId, newSettlementConfiguration
        );

        bytes memory mockSignedReport =
            getMockedSignedReport(fuzzMarketConfig.streamId, fuzzMarketConfig.mockUsdPrice);

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.InvalidDataStreamReport.selector, bytes32(fuzzStreamId), fuzzMarketConfig.streamId
            )
        });

        perpsEngine.exposed_verifyOffchainPrice(
            fuzzMarketConfig.marketId, settlementConfigurationId, mockSignedReport, MAX_VERIFICATION_DELAY
        );
    }

    function testFuzz_RevertWhen_TheBlockTimestampIsGreaterThanThePremiumReportValidFromTimestampSumWithMaxVerificationDelay(
        uint256 marketId,
        uint128 settlementConfigurationId
    )
        external
        whenTheStrategyIsEqualToDataStreamsDefault
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        SettlementConfiguration.DataStreamsStrategy memory dataStreamsStrategy = SettlementConfiguration
            .DataStreamsStrategy({
            chainlinkVerifier: IVerifierProxy(address(mockChainlinkVerifier)),
            streamId: fuzzMarketConfig.streamId
        });

        SettlementConfiguration.Data memory newSettlementConfiguration = SettlementConfiguration.Data({
            strategy: SettlementConfiguration.Strategy.DATA_STREAMS_DEFAULT,
            isEnabled: false,
            fee: DEFAULT_SETTLEMENT_FEE,
            keeper: marketOrderKeepers[fuzzMarketConfig.marketId],
            data: abi.encode(dataStreamsStrategy)
        });

        SettlementConfigurationHarness(perpsEngine).exposed_update(
            fuzzMarketConfig.marketId, settlementConfigurationId, newSettlementConfiguration
        );

        bytes memory mockSignedReport =
            getMockedSignedReportWithValidFromTimestampZero(fuzzMarketConfig.streamId, fuzzMarketConfig.mockUsdPrice);

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.InvalidDataStreamReport.selector, fuzzMarketConfig.streamId, fuzzMarketConfig.streamId
            )
        });

        perpsEngine.exposed_verifyOffchainPrice(
            fuzzMarketConfig.marketId, settlementConfigurationId, mockSignedReport, MAX_VERIFICATION_DELAY
        );
    }

    function testFuzz_WhenDataStreamsReportIsValid(
        uint256 marketId,
        uint128 settlementConfigurationId
    )
        external
        whenTheStrategyIsEqualToDataStreamsDefault
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        SettlementConfiguration.DataStreamsStrategy memory dataStreamsStrategy = SettlementConfiguration
            .DataStreamsStrategy({
            chainlinkVerifier: IVerifierProxy(address(mockChainlinkVerifier)),
            streamId: fuzzMarketConfig.streamId
        });

        SettlementConfiguration.Data memory newSettlementConfiguration = SettlementConfiguration.Data({
            strategy: SettlementConfiguration.Strategy.DATA_STREAMS_DEFAULT,
            isEnabled: false,
            fee: DEFAULT_SETTLEMENT_FEE,
            keeper: marketOrderKeepers[fuzzMarketConfig.marketId],
            data: abi.encode(dataStreamsStrategy)
        });

        SettlementConfigurationHarness(perpsEngine).exposed_update(
            fuzzMarketConfig.marketId, settlementConfigurationId, newSettlementConfiguration
        );

        bytes memory mockSignedReport =
            getMockedSignedReport(fuzzMarketConfig.streamId, fuzzMarketConfig.mockUsdPrice);

        (UD60x18 bidX18, UD60x18 askX18) = perpsEngine.exposed_verifyOffchainPrice(
            fuzzMarketConfig.marketId, settlementConfigurationId, mockSignedReport, MAX_VERIFICATION_DELAY
        );

        // it should return the bidX18
        assertEq(bidX18.intoUint256(), fuzzMarketConfig.mockUsdPrice);

        // it should return the askX18
        assertEq(askX18.intoUint256(), fuzzMarketConfig.mockUsdPrice);
    }
}
