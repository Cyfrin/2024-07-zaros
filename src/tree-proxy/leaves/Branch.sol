// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

library Branch {
    struct Data {
        address branch;
        bytes4[] selectors;
    }
}
