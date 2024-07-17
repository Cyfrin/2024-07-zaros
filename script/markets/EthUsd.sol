// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Constants } from "@zaros/utils/Constants.sol";
import { OrderFees } from "@zaros/perpetuals/leaves/OrderFees.sol";

abstract contract EthUsd {
    /// @notice ETHUSD market configuration parameters.
    uint128 internal constant ETH_USD_MARKET_ID = 2;
    string internal constant ETH_USD_MARKET_NAME = "ETHUSD Perpetual Futures";
    string internal constant ETH_USD_MARKET_SYMBOL = "ETHUSD-PERP";
    uint128 internal constant ETH_USD_IMR = 0.01e18;
    uint128 internal constant ETH_USD_MMR = 0.005e18;
    uint128 internal constant ETH_USD_MARGIN_REQUIREMENTS = ETH_USD_IMR + ETH_USD_MMR;
    uint128 internal constant ETH_USD_MAX_OI = 1_000_000e18;
    uint128 internal constant ETH_USD_MAX_SKEW = 1_000_000e18;
    uint128 internal constant ETH_USD_MAX_FUNDING_VELOCITY = 0.03e18;
    // TODO: update to mainnet value = 1_000_000e18.
    uint256 internal constant ETH_USD_SKEW_SCALE = 10_000_000e18;
    uint128 internal constant ETH_USD_MIN_TRADE_SIZE = 0.05e18;
    OrderFees.Data internal ethUsdOrderFees = OrderFees.Data({ makerFee: 0.0004e18, takerFee: 0.0008e18 });

    /// @notice Test only mocks
    string internal constant MOCK_ETH_USD_STREAM_ID = "MOCK_ETH_USD_STREAM_ID";
    uint256 internal constant MOCK_ETH_USD_PRICE = 1000e18;

    // TODO: Update address value
    address internal constant ETH_USD_PRICE_FEED = address(0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165);
    uint32 internal constant ETH_USD_PRICE_FEED_HEARTBEATS_SECONDS = 120;

    // TODO: Update stream id value
    bytes32 internal constant ETH_USD_STREAM_ID = 0x000359843a543ee2fe414dc14c7e7920ef10f4372990b79d6361cdc0dd1ba782;
    string internal constant STRING_ETH_USD_STREAM_ID =
        "0x000359843a543ee2fe414dc14c7e7920ef10f4372990b79d6361cdc0dd1ba782";
}
