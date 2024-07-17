// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { MarketOrder } from "@zaros/perpetuals/leaves/MarketOrder.sol";

contract MarketOrderHarness {
    function exposed_MarketOrder_load(uint128 tradingAccountId) external pure returns (MarketOrder.Data memory) {
        return MarketOrder.load(tradingAccountId);
    }

    function exposed_MarketOrder_loadExisting(uint128 tradingAccountId)
        external
        view
        returns (MarketOrder.Data memory)
    {
        return MarketOrder.loadExisting(tradingAccountId);
    }

    function exposed_update(uint128 tradingAccountId, uint128 marketId, int128 sizeDelta) external {
        MarketOrder.Data storage self = MarketOrder.load(tradingAccountId);
        MarketOrder.update(self, marketId, sizeDelta);
    }

    function exposed_clear(uint128 tradingAccountId) external {
        MarketOrder.Data storage self = MarketOrder.load(tradingAccountId);
        MarketOrder.clear(self);
    }

    function exposed_checkPendingOrder(uint128 tradingAccountId) external view {
        MarketOrder.Data storage self = MarketOrder.load(tradingAccountId);
        MarketOrder.checkPendingOrder(self);
    }
}
