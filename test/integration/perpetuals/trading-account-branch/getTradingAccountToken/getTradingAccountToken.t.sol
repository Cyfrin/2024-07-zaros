// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";

contract GetTradingAccountToken_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
    }

    function test_GivenTheresAnAccountTokenStored() external {
        address expectedTradingAccountToken = address(tradingAccountToken);
        address tradingAccountToken = perpsEngine.getTradingAccountToken();

        // it should return the stored account token
        assertEq(tradingAccountToken, expectedTradingAccountToken, "getTradingAccountToken");
    }
}
