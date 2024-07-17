// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";

abstract contract WstEth {
    /// @notice Margin collateral configuration parameters.
    string internal constant WSTETH_NAME = "Wrapped liquid staked Ether 2.0";
    string internal constant WSTETH_SYMBOL = "wstETH";
    uint256 internal constant WSTETH_MARGIN_COLLATERAL_ID = 5;
    UD60x18 internal WSTETH_DEPOSIT_CAP_X18 = ud60x18(1_000_000e18);
    uint120 internal constant WSTETH_LOAN_TO_VALUE = 0.7e18;
    uint256 internal constant WSTETH_MIN_DEPOSIT_MARGIN = 0.025e18;
    uint256 internal constant MOCK_WSTETH_USD_PRICE = 2000e18;
    address internal constant WSTETH_ADDRESS = address(0xd9433D0E5b5Ae4593ba3880c25046BBC4dC4926C);
    address internal constant WSTETH_PRICE_FEED = address(0xd9433D0E5b5Ae4593ba3880c25046BBC4dC4926C);
    uint256 internal constant WSTETH_LIQUIDATION_PRIORITY = 5;
    uint8 internal constant WSTETH_DECIMALS = 18;
    uint32 internal constant WSTETH_PRICE_FEED_HEARBEAT_SECONDS = 86_400;
}
