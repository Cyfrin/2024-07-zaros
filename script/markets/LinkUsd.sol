// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Constants } from "@zaros/utils/Constants.sol";
import { OrderFees } from "@zaros/perpetuals/leaves/OrderFees.sol";

abstract contract LinkUsd {
    /// @notice LINKUSD market configuration parameters.
    uint128 internal constant LINK_USD_MARKET_ID = 3;
    string internal constant LINK_USD_MARKET_NAME = "LINKUSD Perpetual";
    string internal constant LINK_USD_MARKET_SYMBOL = "LINKUSD-PERP";
    uint128 internal constant LINK_USD_IMR = 0.05e18;
    uint128 internal constant LINK_USD_MMR = 0.025e18;
    uint128 internal constant LINK_USD_MARGIN_REQUIREMENTS = LINK_USD_IMR + LINK_USD_MMR;
    uint128 internal constant LINK_USD_MAX_OI = 100_000_000e18;
    uint128 internal constant LINK_USD_MAX_SKEW = 100_000_000e18;
    uint128 internal constant LINK_USD_MAX_FUNDING_VELOCITY = 0.03e18;
    uint256 internal constant LINK_USD_SKEW_SCALE = 1_151_243_152e18;
    uint128 internal constant LINK_USD_MIN_TRADE_SIZE = 5e18;
    OrderFees.Data internal linkUsdOrderFees = OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 });

    /// @notice Test only mocks
    string internal constant MOCK_LINK_USD_STREAM_ID = "MOCK_LINK_USD_STREAM_ID";
    uint256 internal constant MOCK_LINK_USD_PRICE = 10e18;

    // TODO: Update address value
    address internal constant LINK_USD_PRICE_FEED = address(0x0FB99723Aee6f420beAD13e6bBB79b7E6F034298);
    uint32 internal constant LINK_USD_PRICE_FEED_HEARTBEATS_SECONDS = 3600;

    // TODO: Update stream id value
    bytes32 internal constant LINK_USD_STREAM_ID = 0x00036fe43f87884450b4c7e093cd5ed99cac6640d8c2000e6afc02c8838d0265;
    string internal constant STRING_LINK_USD_STREAM_ID =
        "0x00036fe43f87884450b4c7e093cd5ed99cac6640d8c2000e6afc02c8838d0265";
}
