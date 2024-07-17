// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";

// Open Zeppelin dependencies
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { ERC20, ERC20Permit } from "@openzeppelin/token/ERC20/extensions/ERC20Permit.sol";

contract USDToken is ERC20Permit, Ownable {
    constructor(address owner) ERC20("Zaros USD", "USDz") ERC20Permit("Zaros USD") Ownable(owner) { }

    function mint(address to, uint256 amount) external onlyOwner {
        _requireAmountNotZero(amount);
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _requireAmountNotZero(amount);
        _burn(msg.sender, amount);
    }

    function _requireAmountNotZero(uint256 amount) private pure {
        if (amount == 0) {
            revert Errors.ZeroInput("amount");
        }
    }
}
