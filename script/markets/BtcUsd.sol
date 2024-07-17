// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Constants } from "@zaros/utils/Constants.sol";
import { OrderFees } from "@zaros/perpetuals/leaves/OrderFees.sol";

abstract contract BtcUsd {
    /// @notice BTCUSD market configuration parameters.
    uint128 internal constant BTC_USD_MARKET_ID = 1;
    string internal constant BTC_USD_MARKET_NAME = "BTCUSD Perpetual Futures";
    string internal constant BTC_USD_MARKET_SYMBOL = "BTCUSD-PERP";
    uint128 internal constant BTC_USD_IMR = 0.01e18;
    uint128 internal constant BTC_USD_MMR = 0.005e18;
    uint128 internal constant BTC_USD_MARGIN_REQUIREMENTS = BTC_USD_IMR + BTC_USD_MMR;
    uint128 internal constant BTC_USD_MAX_OI = 500_000e18;
    uint128 internal constant BTC_USD_MAX_SKEW = 500_000e18;
    uint128 internal constant BTC_USD_MAX_FUNDING_VELOCITY = 0.03e18;
    // TODO: update to mainnet value = 100_000e18.
    uint256 internal constant BTC_USD_SKEW_SCALE = 10_000_000e18;
    uint128 internal constant BTC_USD_MIN_TRADE_SIZE = 0.001e18;
    OrderFees.Data internal btcUsdOrderFees = OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 });

    /// @notice Test only mocks
    string internal constant MOCK_BTC_USD_STREAM_ID = "MOCK_BTC_USD_STREAM_ID";
    uint256 internal constant MOCK_BTC_USD_PRICE = 100_000e18;

    // TODO: Update address value
    address internal constant BTC_USD_PRICE_FEED = address(0x56a43EB56Da12C0dc1D972ACb089c06a5dEF8e69);
    uint32 internal constant BTC_USD_PRICE_FEED_HEARTBEATS_SECONDS = 3600;

    // TODO: Update stream id value
    bytes32 internal constant BTC_USD_STREAM_ID = 0x00037da06d56d083fe599397a4769a042d63aa73dc4ef57709d31e9971a5b439;
    string internal constant STRING_BTC_USD_STREAM_ID =
        "0x00037da06d56d083fe599397a4769a042d63aa73dc4ef57709d31e9971a5b439";
}
