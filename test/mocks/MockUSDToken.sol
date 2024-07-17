// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { USDToken } from "@zaros/usd/USDToken.sol";

contract MockUSDToken is USDToken {
    constructor(address owner, uint256 deployerBalance) USDToken(owner) {
        _mint(owner, deployerBalance);
    }

    function mockMint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
