// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Constants } from "@zaros/utils/Constants.sol";

contract MockPriceFeedWithInvalidReturn {
    function decimals() public pure returns (uint8) {
        return Constants.SYSTEM_DECIMALS;
    }

    function latestRoundData() external pure {
        revert();
    }
}
