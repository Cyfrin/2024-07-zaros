//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";
import { SD59x18, sd59x18 } from "@prb-math/SD59x18.sol";

/// @title The Position namespace.
library Position {
    /// @notice ERC7201 storage location.
    bytes32 internal constant POSITION_LOCATION =
        keccak256(abi.encode(uint256(keccak256("fi.zaros.perpetuals.Position")) - 1)) & ~bytes32(uint256(0xff));

    /// @notice {Position} namespace storage structure.
    /// @param size The position size in asset units, i.e amount of purchased contracts.
    /// @param lastInteractionPrice The last settlement reference price of this position.
    /// @param lastInteractionFundingFeePerUnit The last funding fee per unit applied to this position.
    struct Data {
        int256 size;
        uint128 lastInteractionPrice;
        int128 lastInteractionFundingFeePerUnit;
    }

    /// @param sizeX18 The position openInterest in asset units, i.e amount of purchased contracts.
    /// @param notionalValueX18 The notional value of the position.
    /// @param initialMarginUsdX18 The notional value of the initial margin allocated by the account.
    /// @param maintenanceMarginUsdX18 The notional value of the maintenance margin allocated by the account.
    /// @param entryPriceX18 The last settlement reference price of this position.
    /// @param accruedFundingUsdX18 The accrued funding fee.
    /// @param unrealizedPnlUsdX18 The current unrealized profit or loss of the position.
    struct State {
        SD59x18 sizeX18;
        UD60x18 notionalValueX18;
        UD60x18 initialMarginUsdX18;
        UD60x18 maintenanceMarginUsdX18;
        UD60x18 entryPriceX18;
        SD59x18 accruedFundingUsdX18;
        SD59x18 unrealizedPnlUsdX18;
    }

    /// @notice Loads a {Position}.
    /// @param tradingAccountId The trading account id.
    /// @param marketId The market id.
    function load(uint128 tradingAccountId, uint128 marketId) internal pure returns (Data storage position) {
        bytes32 slot = keccak256(abi.encode(POSITION_LOCATION, tradingAccountId, marketId));

        assembly {
            position.slot := slot
        }
    }

    /// @notice Returns the position's current state.
    /// @param self The position storage pointer.
    /// @param initialMarginRateX18 The market's current initial margin rate.
    /// @param maintenanceMarginRateX18 The market's current maintenance margin rate.
    /// @param price The market's current reference price.
    /// @param fundingFeePerUnit The market's current funding fee per unit.
    /// @return state The position's current state
    function getState(
        Data storage self,
        UD60x18 initialMarginRateX18,
        UD60x18 maintenanceMarginRateX18,
        UD60x18 price,
        SD59x18 fundingFeePerUnit
    )
        internal
        view
        returns (State memory state)
    {
        state.sizeX18 = sd59x18(self.size);
        state.notionalValueX18 = getNotionalValue(self, price);
        state.initialMarginUsdX18 = state.notionalValueX18.mul(initialMarginRateX18);
        state.maintenanceMarginUsdX18 = state.notionalValueX18.mul(maintenanceMarginRateX18);
        state.entryPriceX18 = ud60x18(self.lastInteractionPrice);
        state.accruedFundingUsdX18 = getAccruedFunding(self, fundingFeePerUnit);
        state.unrealizedPnlUsdX18 = getUnrealizedPnl(self, price);
    }

    /// @notice Updates the current position with the new one.
    /// @param self The position storage pointer.
    /// @param newPosition The new position to be placed.
    function update(Data storage self, Data memory newPosition) internal {
        self.size = newPosition.size;
        self.lastInteractionPrice = newPosition.lastInteractionPrice;
        self.lastInteractionFundingFeePerUnit = newPosition.lastInteractionFundingFeePerUnit;
    }

    /// @notice Clears the position data, used when a position is fully closed or liquidated.
    /// @param self The position storage pointer.
    function clear(Data storage self) internal {
        self.size = 0;
        self.lastInteractionPrice = 0;
        self.lastInteractionFundingFeePerUnit = 0;
    }

    /// @notice Returns the accrued funding fee.
    /// @param self The position storage pointer.
    /// @param fundingFeePerUnit The market's current funding fee per unit.
    /// @return accruedFundingUsdX18 The accrued funding fee, positive or negative.
    function getAccruedFunding(
        Data storage self,
        SD59x18 fundingFeePerUnit
    )
        internal
        view
        returns (SD59x18 accruedFundingUsdX18)
    {
        SD59x18 netFundingFeePerUnit = fundingFeePerUnit.sub(sd59x18(self.lastInteractionFundingFeePerUnit));
        accruedFundingUsdX18 = sd59x18(self.size).mul(netFundingFeePerUnit);
    }

    /// @notice Returns the initial and maintenance margin requirements of the position.
    /// @param notionalValueX18 The notional value of the position.
    /// @param initialMarginRateX18 The market's current initial margin rate.
    /// @param maintenanceMarginRateX18 The market's current maintenance margin rate.
    /// @return initialMarginUsdX18 The usd value of the initial margin allocated by the account.
    /// @return maintenanceMarginUsdX18 The usd value of the maintenance margin allocated by the account.
    function getMarginRequirement(
        UD60x18 notionalValueX18,
        UD60x18 initialMarginRateX18,
        UD60x18 maintenanceMarginRateX18
    )
        internal
        pure
        returns (UD60x18 initialMarginUsdX18, UD60x18 maintenanceMarginUsdX18)
    {
        initialMarginUsdX18 = notionalValueX18.mul(initialMarginRateX18);
        maintenanceMarginUsdX18 = notionalValueX18.mul(maintenanceMarginRateX18);
    }

    /// @notice Returns the current unrealized profit or loss of the position.
    /// @param self The position storage pointer.
    /// @param price The market's current reference price.
    /// @return unrealizedPnlUsdX18 The current unrealized profit or loss of the position.
    function getUnrealizedPnl(Data storage self, UD60x18 price) internal view returns (SD59x18 unrealizedPnlUsdX18) {
        SD59x18 priceShift = price.intoSD59x18().sub(ud60x18(self.lastInteractionPrice).intoSD59x18());
        unrealizedPnlUsdX18 = sd59x18(self.size).mul(priceShift);
    }

    /// @notice Returns the notional value of the position.
    /// @param self The position storage pointer.
    /// @param price The market's current reference price.
    function getNotionalValue(Data storage self, UD60x18 price) internal view returns (UD60x18) {
        return sd59x18(self.size).abs().intoUD60x18().mul(price);
    }

    /// @notice Determines if a given position size change is an increase in the position.
    /// @dev This function checks if the position is being opened or increased based on the size delta and the current
    /// position size.
    /// @param tradingAccountId The unique identifier for the trading account.
    /// @param marketId The market identifier where the position is held.
    /// @param sizeDelta The change in position size; positive for an increase, negative for a decrease.
    /// @return isBeingIncreased Returns true if the position is being opened (size is 0) or increased (sizeDelta
    /// direction matches position size), otherwise false.
    function isIncreasing(
        uint128 tradingAccountId,
        uint128 marketId,
        int128 sizeDelta
    )
        internal
        view
        returns (bool)
    {
        Data storage self = Position.load(tradingAccountId, marketId);

        // If position is being opened (size is 0) or if position is being increased (sizeDelta direction is same as
        // position size)
        // For a positive position, sizeDelta should be positive to increase, and for a negative position, sizeDelta
        // should be negative to increase.
        // This also implicitly covers the case where if it's a new position (size is 0), it's considered an increase.
        return self.size == 0 || (self.size > 0 && sizeDelta > 0) || (self.size < 0 && sizeDelta < 0);
    }
}
