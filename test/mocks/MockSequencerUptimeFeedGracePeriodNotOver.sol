// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

contract MockSequencerUptimeFeedGracePeriodNotOver {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 0, block.timestamp, 0, 0);
    }
}
