// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependecies
import { MockAggregator } from "test/mocks/MockAggregator.sol";

contract MockPriceFeed {
    uint8 private _decimals;
    int256 private _price;
    address private _mockAggregator;

    constructor(uint8 decimals_, int256 price_) {
        _decimals = decimals_;
        _price = price_;

        MockAggregator mockAggregator = new MockAggregator(int192(_price - 1), int192(_price + 1));
        _mockAggregator = address(mockAggregator);
    }

    function aggregator() external view returns (address) {
        return _mockAggregator;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, _price, 0, block.timestamp, 0);
    }

    function updateMockPrice(uint256 newPrice) external {
        _price = int256(newPrice);

        MockAggregator mockAggregator =
            new MockAggregator(int192(int256((newPrice - 1))), int192(int256((newPrice + 1))));
        _mockAggregator = address(mockAggregator);
    }

    function updateMockAggregator(int256 min, int256 max) external {
        MockAggregator mockAggregator = new MockAggregator(int192((min)), int192((max)));
        _mockAggregator = address(mockAggregator);
    }
}
