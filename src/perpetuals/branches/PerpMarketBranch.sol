// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { OrderFees } from "../leaves/OrderFees.sol";
import { Position } from "../leaves/Position.sol";
import { PerpMarket } from "../leaves/PerpMarket.sol";
import { SettlementConfiguration } from "../leaves/SettlementConfiguration.sol";

// PRB Math dependencies
import { UD60x18, ud60x18, ZERO as UD60x18_ZERO } from "@prb-math/UD60x18.sol";
import { SD59x18, sd59x18, unary, ZERO as SD59x18_ZERO } from "@prb-math/SD59x18.sol";

/// @title Perps Engine Branch.
/// @notice The perps engine  is responsible by the state management of perps markets.
contract PerpMarketBranch {
    using PerpMarket for PerpMarket.Data;
    using Position for Position.Data;

    /// @notice Returns the given perps market name.
    /// @param marketId The perps market id.
    function getName(uint128 marketId) external view returns (string memory) {
        return PerpMarket.load(marketId).configuration.name;
    }

    /// @notice Returns the given perps market symbol.
    /// @param marketId The perps market id.
    function getSymbol(uint128 marketId) external view returns (string memory) {
        return PerpMarket.load(marketId).configuration.symbol;
    }

    /// @notice Returns the maximum total open interest of the given market.
    /// @param marketId The perps market id.
    function getMaxOpenInterest(uint128 marketId) external view returns (UD60x18) {
        return ud60x18(PerpMarket.load(marketId).configuration.maxOpenInterest);
    }

    /// @notice Returns the maximum skew in one of the market's sides.
    /// @param marketId The perps market id.
    function getMaxSkew(uint128 marketId) external view returns (UD60x18) {
        return ud60x18(PerpMarket.load(marketId).configuration.maxSkew);
    }

    /// @notice Returns the current market skew.
    /// @param marketId The perps market id.
    function getSkew(uint128 marketId) external view returns (SD59x18) {
        return sd59x18(PerpMarket.load(marketId).skew);
    }

    /// @notice Returns the given market's open interest, including the size of longs and shorts.
    /// @dev E.g: There is 500 ETH in long positions and 450 ETH in short positions, this function
    /// should return UD60x18 longsOpenInterest = 500e18 and UD60x18 shortsOpenInterest = 450e18;
    /// @param marketId The perps market id.
    /// @return longsOpenInterest The open interest in long positions.
    /// @return shortsOpenInterest The open interest in short positions.
    /// @return totalOpenInterest The sum of longsOpenInterest and shortsOpenInterest.
    function getOpenInterest(uint128 marketId)
        external
        view
        returns (UD60x18 longsOpenInterest, UD60x18 shortsOpenInterest, UD60x18 totalOpenInterest)
    {
        // fetch storage slot for perp market
        PerpMarket.Data storage perpMarket = PerpMarket.load(marketId);

        // calculate half skew
        SD59x18 halfSkew = sd59x18(perpMarket.skew).div(sd59x18(2e18));

        // load current open interest from storage, convert to signed
        SD59x18 currentOpenInterest = ud60x18(perpMarket.openInterest).intoSD59x18();

        // calculate half current open interest
        SD59x18 halfOpenInterest = currentOpenInterest.div(sd59x18(2e18));

        // prepare outputs
        longsOpenInterest = halfOpenInterest.add(halfSkew).lt(SD59x18_ZERO)
            ? UD60x18_ZERO
            : halfOpenInterest.add(halfSkew).intoUD60x18();

        shortsOpenInterest = unary(halfOpenInterest).add(halfSkew).abs().intoUD60x18();
        totalOpenInterest = longsOpenInterest.add(shortsOpenInterest);
    }

    /// @notice Returns the given market's mark price based on the offchain price.
    /// @dev It returns the adjusted price if the market's skew is being updated.
    /// @param marketId The perps market id.
    /// @param indexPrice The offchain index price.
    /// @param skewDelta The size of the skew update.
    /// @return markPrice The market's mark price.
    function getMarkPrice(uint128 marketId, uint256 indexPrice, int256 skewDelta) external view returns (UD60x18) {
        PerpMarket.Data storage perpMarket = PerpMarket.load(marketId);

        return perpMarket.getMarkPrice(sd59x18(skewDelta), ud60x18(indexPrice));
    }

    /// @notice Returns a Settlement Strategy used by the given market.
    /// @param marketId The perps market id.
    /// @param settlementConfigurationId The perps market settlement configuration id
    function getSettlementConfiguration(
        uint128 marketId,
        uint128 settlementConfigurationId
    )
        external
        pure
        returns (SettlementConfiguration.Data memory)
    {
        return SettlementConfiguration.load(marketId, settlementConfigurationId);
    }

    /// @notice Returns the given market's funding rate.
    /// @param marketId The perps market id.
    function getFundingRate(uint128 marketId) external view returns (SD59x18) {
        return PerpMarket.load(marketId).getCurrentFundingRate();
    }

    /// @notice Returns the given market's funding velocity.
    /// @param marketId The perps market id.
    function getFundingVelocity(uint128 marketId) external view returns (SD59x18) {
        return PerpMarket.load(marketId).getCurrentFundingVelocity();
    }

    /// @notice Returns the most relevant data of the given market.
    /// @param marketId The perps market id.
    /// @return name The market name.
    /// @return symbol The market symbol.
    /// @return initialMarginRateX18 The minimum initial margin rate for the market.
    /// @return maintenanceMarginRateX18 The maintenance margin rate for the market.
    /// @return maxOpenInterest The maximum open interest for the market.
    /// @return maxSkew The maximum skew for the market.
    /// @return minTradeSizeX18 The minimum trade size of the market.
    /// @return skewScale The configured skew scale of the market.
    /// @return orderFees The configured maker and taker order fees of the market.
    function getPerpMarketConfiguration(uint128 marketId)
        external
        view
        returns (
            string memory name,
            string memory symbol,
            uint128 initialMarginRateX18,
            uint128 maintenanceMarginRateX18,
            uint128 maxOpenInterest,
            uint128 maxSkew,
            uint128 minTradeSizeX18,
            uint256 skewScale,
            OrderFees.Data memory orderFees
        )
    {
        PerpMarket.Data storage perpMarket = PerpMarket.load(marketId);

        name = perpMarket.configuration.name;
        symbol = perpMarket.configuration.symbol;
        initialMarginRateX18 = perpMarket.configuration.initialMarginRateX18;
        maintenanceMarginRateX18 = perpMarket.configuration.maintenanceMarginRateX18;
        maxOpenInterest = perpMarket.configuration.maxOpenInterest;
        maxSkew = perpMarket.configuration.maxSkew;
        skewScale = perpMarket.configuration.skewScale;
        minTradeSizeX18 = perpMarket.configuration.minTradeSizeX18;
        orderFees = perpMarket.configuration.orderFees;
    }
}
