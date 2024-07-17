// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { OrderFees } from "./OrderFees.sol";

library MarketConfiguration {
    /// @notice {MarketConfiguration} namespace storage structure.
    /// @param name The perp market name.
    /// @param symbol The perp market symbol.
    /// @param priceAdapter The price oracle contract address.
    /// @param initialMarginRateX18 The initial margin rate in 1e18.
    /// @param maintenanceMarginRateX18 The maintenance margin rate in 1e18.
    /// @param maxOpenInterest The maximum open interest allowed.
    /// @param maxSkew The maximum skew allowed.
    /// @param maxFundingVelocity The maximum funding velocity allowed.
    /// @param minTradeSizeX18 The minimum trade size in 1e18.
    /// @param skewScale The skew scale, a configurable parameter that determines price marking and funding.
    /// @param orderFees The configured maker and taker order fee tiers.
    struct Data {
        string name;
        string symbol;
        address priceAdapter;
        uint128 initialMarginRateX18;
        uint128 maintenanceMarginRateX18;
        uint128 maxOpenInterest;
        uint128 maxSkew;
        uint128 maxFundingVelocity;
        uint128 minTradeSizeX18;
        uint256 skewScale;
        OrderFees.Data orderFees;
        uint32 priceFeedHeartbeatSeconds;
    }

    /// @notice Updates the given market configuration.
    /// @dev See {MarketConfiguration.Data} for parameter details.
    function update(Data storage self, Data memory params) internal {
        self.name = params.name;
        self.symbol = params.symbol;
        self.priceAdapter = params.priceAdapter;
        self.initialMarginRateX18 = params.initialMarginRateX18;
        self.maintenanceMarginRateX18 = params.maintenanceMarginRateX18;
        self.maxOpenInterest = params.maxOpenInterest;
        self.maxSkew = params.maxSkew;
        self.maxFundingVelocity = params.maxFundingVelocity;
        self.minTradeSizeX18 = params.minTradeSizeX18;
        self.skewScale = params.skewScale;
        self.orderFees = params.orderFees;
    }
}
