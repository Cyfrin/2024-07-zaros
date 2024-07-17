// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Constants } from "@zaros/utils/Constants.sol";
import { OrderFees } from "@zaros/perpetuals/leaves/OrderFees.sol";

abstract contract BnbUsd {
    /// @notice BNBUSD market configuration parameters.
    uint128 internal constant BNB_USD_MARKET_ID = 5;
    string internal constant BNB_USD_MARKET_NAME = "BNBUSD Perpetual";
    string internal constant BNB_USD_MARKET_SYMBOL = "BNBUSD-PERP";
    uint128 internal constant BNB_USD_IMR = 0.1e18;
    uint128 internal constant BNB_USD_MMR = 0.05e18;
    uint128 internal constant BNB_USD_MARGIN_REQUIREMENTS = BNB_USD_IMR + BNB_USD_MMR;
    uint128 internal constant BNB_USD_MAX_OI = 100_000e18;
    uint128 internal constant BNB_USD_MAX_SKEW = 100_000e18;
    uint128 internal constant BNB_USD_MAX_FUNDING_VELOCITY = 0.03e18;
    uint256 internal constant BNB_USD_SKEW_SCALE = 650_593_588e18;
    uint128 internal constant BNB_USD_MIN_TRADE_SIZE = 0.1e18;
    OrderFees.Data internal bnbUsdOrderFees = OrderFees.Data({ makerFee: 0.0005e18, takerFee: 0.001e18 });

    /// @notice Test only mocks
    string internal constant MOCK_BNB_USD_STREAM_ID = "MOCK_BNB_USD_STREAM_ID";
    uint256 internal constant MOCK_BNB_USD_PRICE = 600e18;

    // TODO: Update address value
    address internal constant BNB_USD_PRICE_FEED = address(0x53ab995fBb01C617aa1256698aD55b417168bfF9);
    uint32 internal constant BNB_USD_PRICE_FEED_HEARTBEATS_SECONDS = 86_400;

    // TODO: Update stream id value
    bytes32 internal constant BNB_USD_STREAM_ID = 0x000387d7c042a9d5c97c15354b531bd01bf6d3a351e190f2394403cf2f79bde9;
    string internal constant STRING_BNB_USD_STREAM_ID =
        "0x000387d7c042a9d5c97c15354b531bd01bf6d3a351e190f2394403cf2f79bde9";
}
