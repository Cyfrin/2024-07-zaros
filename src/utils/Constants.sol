// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

/// @notice Constants used across the protocol.
library Constants {
    /// @notice Protocol wide standard decimals.
    uint8 internal constant SYSTEM_DECIMALS = 18;
    /// @notice Default period for the proportional funding rate calculations.
    uint256 internal constant PROPORTIONAL_FUNDING_PERIOD = 1 days;
    /// @notice Default grace period for the sequencer uptime feed.
    uint256 internal constant SEQUENCER_GRACE_PERIOD_TIME = 3600;
    /// @notice EIP712 domain name.
    string internal constant ZAROS_DOMAIN_NAME = "Zaros Perpetuals DEX";
    /// @notice EIP712 domain version.
    string internal constant ZAROS_DOMAIN_VERSION = "1";
    /// @notice EIP712 sign offchain order typehash.
    bytes32 internal constant CREATE_OFFCHAIN_ORDER_TYPEHASH = keccak256(
        "CreateOffchainOrder(uint128 tradingAccountId,uint128 marketId,int128 sizeDelta,uint128 targetPrice,bool shouldIncreaseNonce,uint120 nonce,bytes32 salt)"
    );
}
