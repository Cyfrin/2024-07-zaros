// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

library OffchainOrder {
    /// @notice {OffchainOrder} namespace storage structure.
    /// @param tradingAccountId The trading account id that created the order offchain.
    /// @param marketId The target market id of the offchain order.
    /// @param sizeDelta The size delta of the offchain order.
    /// @param targetPrice The minimum or maximum price of the offchain order.
    /// @param shouldIncreaseNonce Whether the trading account's nonce should be incremented or not.
    /// @param nonce The signed index used to verify whether a given order is still valid or not.
    /// @param salt A random 32 bytes value generated and signed offchain to distinguish an offchain order.
    /// @param v ECDSA signature recovery id.
    /// @param r ECDSA signature output.
    /// @param s ECDSA signature output.
    struct Data {
        uint128 tradingAccountId;
        uint128 marketId;
        int128 sizeDelta;
        uint128 targetPrice;
        bool shouldIncreaseNonce;
        uint120 nonce;
        bytes32 salt;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}
