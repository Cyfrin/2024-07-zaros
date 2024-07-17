// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

import { IOffchainAggregator } from "@zaros/external/chainlink/interfaces/IOffchainAggregator.sol";

contract MockAggregator {
    // Lowest answer the system is allowed to report in response to transmissions
    int192 public immutable _minAnswer;
    // Highest answer the system is allowed to report in response to transmissions
    int192 public immutable _maxAnswer;

    constructor(int192 min, int192 max) {
        _minAnswer = min;
        _maxAnswer = max;
    }

    function minAnswer() external view returns (int192) {
        return _minAnswer;
    }

    function maxAnswer() external view returns (int192) {
        return _maxAnswer;
    }
}
