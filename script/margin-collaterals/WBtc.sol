// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";

abstract contract WBtc {
    /// @notice Margin collateral configuration parameters.
    string internal constant WBTC_NAME = "Wrapped BTC";
    string internal constant WBTC_SYMBOL = "WBTC";
    uint256 internal constant WBTC_MARGIN_COLLATERAL_ID = 4;
    UD60x18 internal WBTC_DEPOSIT_CAP_X18 = ud60x18(1_000_000e18);
    uint120 internal constant WBTC_LOAN_TO_VALUE = 0.85e18;
    uint256 internal constant WBTC_MIN_DEPOSIT_MARGIN = 0.025e8;
    uint256 internal constant MOCK_WBTC_USD_PRICE = 2000e18;
    address internal constant WBTC_ADDRESS = address(0xd9433D0E5b5Ae4593ba3880c25046BBC4dC4926C);
    address internal constant WBTC_PRICE_FEED = address(0xd9433D0E5b5Ae4593ba3880c25046BBC4dC4926C);
    uint256 internal constant WBTC_LIQUIDATION_PRIORITY = 4;
    uint8 internal constant WBTC_DECIMALS = 8;
    uint32 internal constant WBTC_PRICE_FEED_HEARBEAT_SECONDS = 86_400;
}
