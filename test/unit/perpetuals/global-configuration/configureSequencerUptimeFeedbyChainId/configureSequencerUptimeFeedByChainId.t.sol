// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { Base_Test } from "test/Base.t.sol";
import { GlobalConfigurationBranch } from "@zaros/perpetuals/branches/GlobalConfigurationBranch.sol";

contract ConfigureSequencerUptimeFeedByChainId_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
    }

    function test_RevertWhen_ChainIdArrayLengthIsZero() external {
        uint256[] memory chainIds = new uint256[](0);
        address[] memory sequencerUptimeFeeds = new address[](1);
        sequencerUptimeFeeds[0] = address(ARBITRUM_SEQUENCER_UPTIME_FEED);

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "chainIds") });

        perpsEngine.configureSequencerUptimeFeedByChainId(chainIds, sequencerUptimeFeeds);
    }

    function test_RevertWhen_SequencerUptimeFeedArrayLengthIsZero() external {
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = 4216;
        address[] memory sequencerUptimeFeeds = new address[](0);

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "sequencerUptimeFeedAddresses")
        });

        perpsEngine.configureSequencerUptimeFeedByChainId(chainIds, sequencerUptimeFeeds);
    }

    function test_RevertWhen_ChainIdArrayAndSequencerUptimeFeedArrayHasADifferentLength() external {
        uint256[] memory chainIds = new uint256[](2);
        chainIds[0] = 4216;
        chainIds[1] = 1;
        address[] memory sequencerUptimeFeeds = new address[](1);
        sequencerUptimeFeeds[0] = address(ARBITRUM_SEQUENCER_UPTIME_FEED);

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.ArrayLengthMismatch.selector, chainIds.length, sequencerUptimeFeeds.length
            )
        });

        perpsEngine.configureSequencerUptimeFeedByChainId(chainIds, sequencerUptimeFeeds);
    }

    function test_WhenChainIdArrayAndSequencerUptimeFeedArrayAreValid() external {
        uint256[] memory chainIds = new uint256[](2);
        chainIds[0] = 4216;
        chainIds[1] = 1;
        address[] memory sequencerUptimeFeeds = new address[](2);
        sequencerUptimeFeeds[0] = address(ARBITRUM_SEQUENCER_UPTIME_FEED);
        sequencerUptimeFeeds[1] = address(0x123);

        for (uint256 i; i < chainIds.length; i++) {
            // it should emit {LogSetSequencerUptimeFeed} event
            vm.expectEmit({ emitter: address(perpsEngine) });
            emit GlobalConfigurationBranch.LogSetSequencerUptimeFeed(
                users.owner.account, chainIds[i], sequencerUptimeFeeds[i]
            );
        }

        perpsEngine.configureSequencerUptimeFeedByChainId(chainIds, sequencerUptimeFeeds);

        for (uint256 i; i < chainIds.length; i++) {
            address expectedSequencerUptimeFeed = sequencerUptimeFeeds[i];
            address receivedSequencerUptimeFeed = perpsEngine.workaround_getSequencerUptimeFeedByChainId(chainIds[i]);

            // it should configure the sequencer uptime feed with your chain id
            assertEq(
                expectedSequencerUptimeFeed,
                receivedSequencerUptimeFeed,
                "The sequencer uptime feed was not configured correctly"
            );
        }
    }
}
