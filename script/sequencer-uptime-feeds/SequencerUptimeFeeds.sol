// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { IPerpsEngine } from "@zaros/perpetuals/PerpsEngine.sol";

// Sequencer Uptime Feeds
import { Arbitrum } from "./Arbitrum.sol";

contract SequencerUptimeFeeds is Arbitrum {
    function configureSequencerUptimeFeeds(IPerpsEngine perpsEngine) internal {
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = ARBITRUM_CHAIN_ID;

        address[] memory feeds = new address[](1);
        feeds[0] = ARBITRUM_SEQUENCER_UPTIME_FEED;

        perpsEngine.configureSequencerUptimeFeedByChainId(chainIds, feeds);
    }
}
