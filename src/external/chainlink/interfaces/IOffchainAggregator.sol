// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

interface IOffchainAggregator {
    function minAnswer() external view returns (int192);

    function maxAnswer() external view returns (int192);
}
