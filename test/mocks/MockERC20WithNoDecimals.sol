// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { MockERC20 } from "./MockERC20.sol";

// Open Zeppelin dependencies
import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";

contract MockERC20WithNoDecimals is ERC20 {
    uint8 internal _decimals;

    constructor(string memory name, string memory symbol, uint256 deployerBalance) ERC20(name, symbol) {
        _mint(msg.sender, deployerBalance);
    }

    function decimals() public pure override returns (uint8) {
        revert();
    }
}
