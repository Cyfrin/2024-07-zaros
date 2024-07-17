// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

library FeeRecipients {
    /// @param marginCollateralRecipient The address that will receive liquidated or deducted margin collateral
    /// @param orderFeeRecipient The address that will receive the order fees
    /// @param settlementFeeRecipient The address that will receive the settlement fees
    struct Data {
        address marginCollateralRecipient;
        address orderFeeRecipient;
        address settlementFeeRecipient;
    }
}
