// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Constants } from "@zaros/utils/Constants.sol";
import { OrderFees } from "@zaros/perpetuals/leaves/OrderFees.sol";

abstract contract SolUsd {
    /// @notice SOLUSD market configuration parameters.
    uint128 internal constant SOL_USD_MARKET_ID = 7;
    string internal constant SOL_USD_MARKET_NAME = "SOLUSD Perpetual";
    string internal constant SOL_USD_MARKET_SYMBOL = "SOLUSD-PERP";
    uint128 internal constant SOL_USD_IMR = 0.1e18;
    uint128 internal constant SOL_USD_MMR = 0.05e18;
    uint128 internal constant SOL_USD_MARGIN_REQUIREMENTS = SOL_USD_IMR + SOL_USD_MMR;
    uint128 internal constant SOL_USD_MAX_OI = 1_000_000e18;
    uint128 internal constant SOL_USD_MAX_SKEW = 1_000_000e18;
    uint128 internal constant SOL_USD_MAX_FUNDING_VELOCITY = 0.03e18;
    uint256 internal constant SOL_USD_SKEW_SCALE = 296_872_247e18;
    uint128 internal constant SOL_USD_MIN_TRADE_SIZE = 1e18;
    OrderFees.Data internal solUsdOrderFees = OrderFees.Data({ makerFee: 0.0005e18, takerFee: 0.001e18 });

    /// @notice Test only mocks
    string internal constant MOCK_SOL_USD_STREAM_ID = "MOCK_SOL_USD_STREAM_ID";
    uint256 internal constant MOCK_SOL_USD_PRICE = 167.72e18;

    // TODO: Update address value
    address internal constant SOL_USD_PRICE_FEED = address(0x32377717BC9F9bA8Db45A244bCE77e7c0Cc5A775);
    uint32 internal constant SOL_USD_PRICE_FEED_HEARTBEATS_SECONDS = 86_400;

    // TODO: Update stream id value
    bytes32 internal constant SOL_USD_STREAM_ID = 0x0003d338ea2ac3be9e026033b1aa601673c37bab5e13851c59966f9f820754d6;
    string internal constant STRING_SOL_USD_STREAM_ID =
        "0x0003d338ea2ac3be9e026033b1aa601673c37bab5e13851c59966f9f820754d6";
}
