// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Constants } from "@zaros/utils/Constants.sol";
import { OrderFees } from "@zaros/perpetuals/leaves/OrderFees.sol";

abstract contract ArbUsd {
    /// @notice ARBUSD market configuration parameters.
    uint128 internal constant ARB_USD_MARKET_ID = 4;
    string internal constant ARB_USD_MARKET_NAME = "ARBUSD Perpetual";
    string internal constant ARB_USD_MARKET_SYMBOL = "ARBUSD-PERP";
    uint128 internal constant ARB_USD_IMR = 0.1e18;
    uint128 internal constant ARB_USD_MMR = 0.05e18;
    uint128 internal constant ARB_USD_MARGIN_REQUIREMENTS = ARB_USD_IMR + ARB_USD_MMR;
    uint128 internal constant ARB_USD_MAX_OI = 100_000_000e18;
    uint128 internal constant ARB_USD_MAX_SKEW = 100_000_000e18;
    uint128 internal constant ARB_USD_MAX_FUNDING_VELOCITY = 0.03e18;
    uint256 internal constant ARB_USD_SKEW_SCALE = 100_243_316_353e18;
    uint128 internal constant ARB_USD_MIN_TRADE_SIZE = 40e18;
    OrderFees.Data internal arbUsdOrderFees = OrderFees.Data({ makerFee: 0.008e18, takerFee: 0.016e18 });

    /// @notice Test only mocks
    string internal constant MOCK_ARB_USD_STREAM_ID = "MOCK_ARB_USD_STREAM_ID";
    uint256 internal constant MOCK_ARB_USD_PRICE = 1e18;

    // TODO: Update address value
    address internal constant ARB_USD_PRICE_FEED = address(0xD1092a65338d049DB68D7Be6bD89d17a0929945e);
    uint32 internal constant ARB_USD_PRICE_FEED_HEARTBEATS_SECONDS = 86_400;

    // TODO: Update stream id value
    bytes32 internal constant ARB_USD_STREAM_ID = 0x0003c90f4d0e133914a02466e44f3392560c86248925ce651ef8e44f1ec2ef4a;
    string internal constant STRING_ARB_USD_STREAM_ID =
        "0x0003c90f4d0e133914a02466e44f3392560c86248925ce651ef8e44f1ec2ef4a";
}
