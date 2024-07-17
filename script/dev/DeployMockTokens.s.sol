// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { BaseScript } from "../Base.s.sol";
import { MockERC20 } from "../../test/mocks/MockERC20.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployMockTokens is BaseScript {
    function run() public broadcaster returns (MockERC20, MockERC20) {
        MockERC20 usdc =
            new MockERC20({ name: "USD Coin", symbol: "USDC", decimals_: 6, deployerBalance: 1_000_000_000e6 });
        MockERC20 usdToken =
            new MockERC20({ name: "Zaros USD", symbol: "USDz", decimals_: 18, deployerBalance: 1_000_000_000e18 });

        return (usdc, usdToken);
    }
}
