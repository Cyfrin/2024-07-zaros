// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Constants } from "@zaros/utils/Constants.sol";
import { OrderFees } from "@zaros/perpetuals/leaves/OrderFees.sol";

abstract contract DogeUsd {
    /// @notice DOGEUSD market configuration parameters.
    uint128 internal constant DOGE_USD_MARKET_ID = 6;
    string internal constant DOGE_USD_MARKET_NAME = "DOGEUSD Perpetual";
    string internal constant DOGE_USD_MARKET_SYMBOL = "DOGEUSD-PERP";
    uint128 internal constant DOGE_USD_IMR = 0.1e18;
    uint128 internal constant DOGE_USD_MMR = 0.05e18;
    uint128 internal constant DOGE_USD_MARGIN_REQUIREMENTS = DOGE_USD_IMR + DOGE_USD_MMR;
    uint128 internal constant DOGE_USD_MAX_OI = 500_000_000e18;
    uint128 internal constant DOGE_USD_MAX_SKEW = 500_000_000e18;
    uint128 internal constant DOGE_USD_MAX_FUNDING_VELOCITY = 0.03e18;
    uint256 internal constant DOGE_USD_SKEW_SCALE = 2_415_071_153_532e18;
    uint128 internal constant DOGE_USD_MIN_TRADE_SIZE = 300e18;
    OrderFees.Data internal dogeUsdOrderFees = OrderFees.Data({ makerFee: 0.0005e18, takerFee: 0.001e18 });

    /// @notice Test only mocks
    string internal constant MOCK_DOGE_USD_STREAM_ID = "MOCK_DOGE_USD_STREAM_ID";
    uint256 internal constant MOCK_DOGE_USD_PRICE = 0.15e18;

    // TODO: Update address value
    address internal constant DOGE_USD_PRICE_FEED = address(0x46C81F11b0e49F909eD80760b342B24C46a273D3);
    uint32 internal constant DOGE_USD_PRICE_FEED_HEARTBEATS_SECONDS = 86_400;

    // TODO: Update stream id value
    bytes32 internal constant DOGE_USD_STREAM_ID = 0x00032057c7f224d0266b4311a81cdc3e38145e36442713350d3300fb12e85c99;
    string internal constant STRING_DOGE_USD_STREAM_ID =
        "0x00032057c7f224d0266b4311a81cdc3e38145e36442713350d3300fb12e85c99";
}
