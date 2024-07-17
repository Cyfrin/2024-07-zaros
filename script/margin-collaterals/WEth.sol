// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";

abstract contract WEth {
    /// @notice Margin collateral configuration parameters.
    string internal constant WETH_NAME = "Wrapped Ether";
    string internal constant WETH_SYMBOL = "WETH";
    uint256 internal constant WETH_MARGIN_COLLATERAL_ID = 3;
    UD60x18 internal WETH_DEPOSIT_CAP_X18 = ud60x18(1_000_000e18);
    uint120 internal constant WETH_LOAN_TO_VALUE = 0.85e18;
    uint256 internal constant WETH_MIN_DEPOSIT_MARGIN = 0.025e18;
    uint256 internal constant MOCK_WETH_USD_PRICE = 2000e18;
    address internal constant WETH_ADDRESS = address(0xd9433D0E5b5Ae4593ba3880c25046BBC4dC4926C);
    address internal constant WETH_PRICE_FEED = address(0xd9433D0E5b5Ae4593ba3880c25046BBC4dC4926C);
    uint256 internal constant WETH_LIQUIDATION_PRIORITY = 3;
    uint8 internal constant WETH_DECIMALS = 18;
    uint32 internal constant WETH_PRICE_FEED_HEARBEAT_SECONDS = 86_400;
}
