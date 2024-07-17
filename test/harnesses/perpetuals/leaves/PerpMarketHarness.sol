// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { PerpMarket } from "@zaros/perpetuals/leaves/PerpMarket.sol";

// PRB Math dependencies
import { UD60x18 } from "@prb-math/UD60x18.sol";
import { SD59x18 } from "@prb-math/SD59x18.sol";

contract PerpMarketHarness {
    function exposed_PerpMarket_load(uint128 marketId) external pure returns (PerpMarket.Data memory) {
        return PerpMarket.load(marketId);
    }

    function exposed_getIndexPrice(uint128 marketId) external view returns (UD60x18) {
        PerpMarket.Data storage self = PerpMarket.load(marketId);
        return PerpMarket.getIndexPrice(self);
    }

    function exposed_getMarkPrice(
        uint128 marketId,
        SD59x18 skewDelta,
        UD60x18 indexPriceX18
    )
        external
        view
        returns (UD60x18)
    {
        PerpMarket.Data storage self = PerpMarket.load(marketId);
        return PerpMarket.getMarkPrice(self, skewDelta, indexPriceX18);
    }

    function exposed_getCurrentFundingRate(uint128 marketId) external view returns (SD59x18) {
        PerpMarket.Data storage self = PerpMarket.load(marketId);
        return PerpMarket.getCurrentFundingRate(self);
    }

    function exposed_getCurrentFundingVelocity(uint128 marketId) external view returns (SD59x18) {
        PerpMarket.Data storage self = PerpMarket.load(marketId);
        return PerpMarket.getCurrentFundingVelocity(self);
    }

    function exposed_getOrderFeeUsd(
        uint128 marketId,
        SD59x18 sizeDelta,
        UD60x18 markPriceX18
    )
        external
        view
        returns (UD60x18)
    {
        PerpMarket.Data storage self = PerpMarket.load(marketId);
        return PerpMarket.getOrderFeeUsd(self, sizeDelta, markPriceX18);
    }

    function exposed_getNextFundingFeePerUnit(
        uint128 marketId,
        SD59x18 fundingRate,
        UD60x18 price
    )
        external
        view
        returns (SD59x18)
    {
        PerpMarket.Data storage self = PerpMarket.load(marketId);
        return PerpMarket.getNextFundingFeePerUnit(self, fundingRate, price);
    }

    function exposed_getPendingFundingFeePerUnit(
        uint128 marketId,
        SD59x18 fundingRate,
        UD60x18 price
    )
        external
        view
        returns (SD59x18)
    {
        PerpMarket.Data storage self = PerpMarket.load(marketId);
        return PerpMarket.getPendingFundingFeePerUnit(self, fundingRate, price);
    }

    function exposed_getProportionalElapsedSinceLastFunding(uint128 marketId) external view returns (UD60x18) {
        PerpMarket.Data storage self = PerpMarket.load(marketId);
        return PerpMarket.getProportionalElapsedSinceLastFunding(self);
    }

    function exposed_checkOpenInterestLimits(
        uint128 marketId,
        SD59x18 sizeDelta,
        SD59x18 oldPositionSize,
        SD59x18 newPositionSize
    )
        external
        view
        returns (UD60x18 newOpenInterest, SD59x18 newSkew)
    {
        PerpMarket.Data storage self = PerpMarket.load(marketId);
        return PerpMarket.checkOpenInterestLimits(self, sizeDelta, oldPositionSize, newPositionSize);
    }

    function exposed_checkTradeSize(uint128 marketId, SD59x18 sizeDeltaX18) external view {
        PerpMarket.Data storage self = PerpMarket.load(marketId);
        PerpMarket.checkTradeSize(self, sizeDeltaX18);
    }

    function exposed_updateFunding(uint128 marketId, SD59x18 fundingRate, SD59x18 fundingFeePerUnit) external {
        PerpMarket.Data storage self = PerpMarket.load(marketId);
        PerpMarket.updateFunding(self, fundingRate, fundingFeePerUnit);
    }

    function exposed_updateOpenInterest(uint128 marketId, UD60x18 newOpenInterest, SD59x18 newSkew) external {
        PerpMarket.Data storage self = PerpMarket.load(marketId);
        PerpMarket.updateOpenInterest(self, newOpenInterest, newSkew);
    }

    function exposed_create(PerpMarket.CreateParams memory params) external {
        PerpMarket.create(params);
    }
}
