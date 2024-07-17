// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { BaseScript } from "../Base.s.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DisperseETH is BaseScript {
    address[] public receivers = [
        address(uint160(0xe3B5076a39edd97481d078eff3c54D3c5da6b105)),
        address(uint160(0x7FE07A4eAa179de0540e946BA2C5d7BAfd544563)),
        address(uint160(0x0640cb62BaB2FdFE681237039Ef0b2a665eE352A)),
        address(uint160(0xa6DbB7707Fbf744949E480827220F25Ac4257235)),
        address(uint160(0x5A11a23Ba76534a269562ea86Aa4e254F46e4377)),
        address(uint160(0x43741AA5AD8CCb3A0fb6EEC534c8380d7B3Ce741)),
        address(uint160(0x111419b0173Ff13896b0771A0BE4c8cEC325485d)),
        address(uint160(0x73436522e6193f2980b0a3210E22Abe5ed4F09b9)),
        address(uint160(0xF61F795EfAE4aa813D4C2B1483E7674697b42B7C)),
        address(uint160(0x7aF319D9138D30C191DEfDA0BDED91CA5D411c9C)),
        address(uint160(0x7c7982945E70b4428a7Ffc400bb60713C4dA0Fa3)),
        address(uint160(0xAcCE497F3cC93CBF8453Ebf052980485cf32ba2f)),
        address(uint160(0x0d5880bA57De46d6e00CA5d7A5d25A7eb9b573e7))
    ];

    function run() public broadcaster returns (uint256) {
        uint256 disperseAmount = 0.777e18;
        uint256 totalAmount = disperseAmount * receivers.length;

        for (uint256 i; i < receivers.length; i++) {
            payable(receivers[i]).transfer(disperseAmount);
        }

        return (totalAmount);
    }
}
