// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { GlobalConfiguration } from "./GlobalConfiguration.sol";

library MarketOrder {
    using GlobalConfiguration for GlobalConfiguration.Data;

    /// @notice ERC7201 storage location.
    bytes32 internal constant MARKET_ORDER_LOCATION =
        keccak256(abi.encode(uint256(keccak256("fi.zaros.perpetuals.MarketOrder")) - 1)) & ~bytes32(uint256(0xff));

    /// @notice {MarketOrder} namespace storage structure.
    /// @param marketId The market id of the active market order.
    /// @param sizeDelta The size delta of the active market order.
    /// @param timestamp The timestamp of the market order creation.
    struct Data {
        uint128 marketId;
        int128 sizeDelta;
        uint128 timestamp;
    }

    function load(uint128 tradingAccountId) internal pure returns (Data storage self) {
        bytes32 slot = keccak256(abi.encode(MARKET_ORDER_LOCATION, tradingAccountId));

        assembly {
            self.slot := slot
        }
    }

    function loadExisting(uint128 tradingAccountId) internal view returns (Data storage self) {
        self = load(tradingAccountId);

        if (self.marketId == 0) {
            revert Errors.NoActiveMarketOrder(tradingAccountId);
        }

        return self;
    }

    function update(Data storage self, uint128 marketId, int128 sizeDelta) internal {
        self.marketId = marketId;
        self.sizeDelta = sizeDelta;
        self.timestamp = uint128(block.timestamp);
    }

    function clear(Data storage self) internal {
        self.marketId = 0;
        self.sizeDelta = 0;
        self.timestamp = 0;
    }

    function checkPendingOrder(Data storage self) internal view {
        GlobalConfiguration.Data storage globalConfiguration = GlobalConfiguration.load();
        uint128 marketOrderMinLifetime = globalConfiguration.marketOrderMinLifetime;

        if (
            self.timestamp != 0 && marketOrderMinLifetime != 0
                && block.timestamp - self.timestamp <= marketOrderMinLifetime
        ) {
            revert Errors.MarketOrderStillPending(self.timestamp);
        }
    }
}
