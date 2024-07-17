// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Position } from "@zaros/perpetuals/leaves/Position.sol";

// PRB Math dependencies
import { UD60x18 } from "@prb-math/UD60x18.sol";
import { SD59x18 } from "@prb-math/SD59x18.sol";

contract PositionHarness {
    function exposed_Position_load(
        uint128 tradingAccountId,
        uint128 marketId
    )
        external
        pure
        returns (Position.Data memory)
    {
        return Position.load(tradingAccountId, marketId);
    }

    function exposed_getState(
        uint128 tradingAccountId,
        uint128 marketId,
        UD60x18 initialMarginRateX18,
        UD60x18 maintenanceMarginRateX18,
        UD60x18 price,
        SD59x18 fundingFeePerUnit
    )
        external
        view
        returns (Position.State memory)
    {
        Position.Data storage self = Position.load(tradingAccountId, marketId);
        return Position.getState(self, initialMarginRateX18, maintenanceMarginRateX18, price, fundingFeePerUnit);
    }

    function exposed_update(uint128 tradingAccountId, uint128 marketId, Position.Data memory newPosition) external {
        Position.Data storage self = Position.load(tradingAccountId, marketId);
        Position.update(self, newPosition);
    }

    function exposed_clear(uint128 tradingAccountId, uint128 marketId) external {
        Position.Data storage self = Position.load(tradingAccountId, marketId);
        Position.clear(self);
    }

    function exposed_getAccruedFunding(
        uint128 tradingAccountId,
        uint128 marketId,
        SD59x18 fundingFeePerUnit
    )
        external
        view
        returns (SD59x18)
    {
        Position.Data storage self = Position.load(tradingAccountId, marketId);
        return Position.getAccruedFunding(self, fundingFeePerUnit);
    }

    function exposed_getMarginRequirements(
        UD60x18 notionalValueX18,
        UD60x18 initialMarginRateX18,
        UD60x18 maintenanceMarginRateX18
    )
        external
        pure
        returns (UD60x18, UD60x18)
    {
        return Position.getMarginRequirement(notionalValueX18, initialMarginRateX18, maintenanceMarginRateX18);
    }

    function exposed_getUnrealizedPnl(
        uint128 tradingAccountId,
        uint128 marketId,
        UD60x18 price
    )
        external
        view
        returns (SD59x18)
    {
        Position.Data storage self = Position.load(tradingAccountId, marketId);
        return Position.getUnrealizedPnl(self, price);
    }

    function exposed_getNotionalValue(
        uint128 tradingAccountId,
        uint128 marketId,
        UD60x18 price
    )
        external
        view
        returns (UD60x18)
    {
        Position.Data storage self = Position.load(tradingAccountId, marketId);
        return Position.getNotionalValue(self, price);
    }
}
