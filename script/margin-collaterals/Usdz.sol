// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";

abstract contract Usdz {
    /// @notice Margin collateral configuration parameters.
    string internal constant USDZ_NAME = "Zaros USD";
    string internal constant USDZ_SYMBOL = "USDZ";
    uint256 internal constant USDZ_MARGIN_COLLATERAL_ID = 1;
    UD60x18 internal USDZ_DEPOSIT_CAP_X18 = ud60x18(50_000_000_000e18);
    uint120 internal constant USDZ_LOAN_TO_VALUE = 1e18;
    uint256 internal constant USDZ_MIN_DEPOSIT_MARGIN = 50e18;
    uint256 internal constant MOCK_USDZ_USD_PRICE = 1e18;
    address internal constant USDZ_ADDRESS = address(0x64538B87a4C0554DFabf0A30943C351c8196858E);
    address internal constant USDZ_PRICE_FEED = address(0x0153002d20B96532C639313c2d54c3dA09109309);
    uint256 internal constant USDZ_LIQUIDATION_PRIORITY = 1;
    uint8 internal constant USDZ_DECIMALS = 18;
    uint32 internal constant USDZ_PRICE_FEED_HEARBEAT_SECONDS = 86_400;
}
