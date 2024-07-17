// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { MockPriceFeed } from "test/mocks/MockPriceFeed.sol";

struct Users {
    // Default owner for all Zaros contracts.
    User owner;
    // Address that receives margin collateral from trading accounts.
    User marginCollateralRecipient;
    // Address that receives order fee payments.
    User orderFeeRecipient;
    // Address that receives settlement fee payments.
    User settlementFeeRecipient;
    // Address that receives liquidation fee payments.
    User liquidationFeeRecipient;
    // Default forwarder for Chainlink Automation-powered keepers
    User keepersForwarder;
    // Impartial user 1.
    User naruto;
    // Impartial user 2.
    User sasuke;
    // Impartial user 3.
    User sakura;
    // Malicious user.
    User madara;
}

struct User {
    address payable account;
    uint256 privateKey;
}

struct MockPriceAdapters {
    MockPriceFeed mockBtcUsdPriceAdapter;
    MockPriceFeed mockEthUsdPriceAdapter;
    MockPriceFeed mockLinkUsdPriceAdapter;
    MockPriceFeed mockUsdcUsdPriceAdapter;
    MockPriceFeed mockWstEthUsdPriceAdapter;
}
