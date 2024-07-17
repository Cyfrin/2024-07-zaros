// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

contract MockSequencerUptimeFeed {
    int256 private _anwser;

    constructor(int256 anwser) {
        _anwser = anwser;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, _anwser, 0, block.timestamp, 0);
    }

    function updateAnswer(uint256 newPrice) external {
        _anwser = int256(newPrice);
    }
}
