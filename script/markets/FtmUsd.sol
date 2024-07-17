// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Constants } from "@zaros/utils/Constants.sol";
import { OrderFees } from "@zaros/perpetuals/leaves/OrderFees.sol";

abstract contract FtmUsd {
    /// @notice FTMUSD market configuration parameters.
    uint128 internal constant FTM_USD_MARKET_ID = 10;
    string internal constant FTM_USD_MARKET_NAME = "FTMUSD Perpetual";
    string internal constant FTM_USD_MARKET_SYMBOL = "FTMUSD-PERP";
    uint128 internal constant FTM_USD_IMR = 0.1e18;
    uint128 internal constant FTM_USD_MMR = 0.05e18;
    uint128 internal constant FTM_USD_MARGIN_REQUIREMENTS = FTM_USD_IMR + FTM_USD_MMR;
    uint128 internal constant FTM_USD_MAX_OI = 500_000_000e18;
    uint128 internal constant FTM_USD_MAX_SKEW = 500_000_000e18;
    uint128 internal constant FTM_USD_MAX_FUNDING_VELOCITY = 0.03e18;
    uint256 internal constant FTM_USD_SKEW_SCALE = 12_462_757_437e18;
    uint128 internal constant FTM_USD_MIN_TRADE_SIZE = 250e18;
    OrderFees.Data internal ftmUsdOrderFees = OrderFees.Data({ makerFee: 0.0005e18, takerFee: 0.001e18 });

    /// @notice Test only mocks
    string internal constant MOCK_FTM_USD_STREAM_ID = "MOCK_FTM_USD_STREAM_ID";
    uint256 internal constant MOCK_FTM_USD_PRICE = 0.8e18;

    // TODO: Update address value
    address internal constant FTM_USD_PRICE_FEED = address(0x8A592fCc0cA4cdA594919af08daD910013b361B8);
    uint32 internal constant FTM_USD_PRICE_FEED_HEARTBEATS_SECONDS = 86_400;

    // TODO: Update stream id value
    bytes32 internal constant FTM_USD_STREAM_ID = 0x0003c0cb688504dc63298cc1c61e5bdaa3542f8bf98c996f370c30f820e04a9f;
    string internal constant STRING_FTM_USD_STREAM_ID =
        "0x0003c0cb688504dc63298cc1c61e5bdaa3542f8bf98c996f370c30f820e04a9f";
}
