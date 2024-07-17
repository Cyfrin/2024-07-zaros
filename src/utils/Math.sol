// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";
import { SD59x18, sd59x18 } from "@prb-math/SD59x18.sol";

library Math {
    function divUp(SD59x18 a, SD59x18 b) internal pure returns (SD59x18) {
        return a.mod(b).isZero() ? a.div(b) : a.div(b).add(sd59x18(1));
    }

    function divUp(UD60x18 a, UD60x18 b) internal pure returns (UD60x18) {
        return a.mod(b).isZero() ? a.div(b) : a.div(b).add(ud60x18(1));
    }

    function max(SD59x18 a, SD59x18 b) internal pure returns (SD59x18) {
        return a.gt(b) ? a : b;
    }

    function max(UD60x18 a, UD60x18 b) internal pure returns (UD60x18) {
        return a.gt(b) ? a : b;
    }

    function min(SD59x18 a, SD59x18 b) internal pure returns (SD59x18) {
        return a.lt(b) ? a : b;
    }

    function min(UD60x18 a, UD60x18 b) internal pure returns (UD60x18) {
        return a.lt(b) ? a : b;
    }
}
