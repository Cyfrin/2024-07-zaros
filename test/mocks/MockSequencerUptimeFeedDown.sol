// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

contract MockSequencerUptimeFeedDown {
    function latestRoundData()
        external
        pure
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 1, 0, 0, 0);
    }
}
