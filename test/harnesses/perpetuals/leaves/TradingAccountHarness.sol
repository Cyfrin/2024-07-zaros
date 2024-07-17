// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { TradingAccount } from "@zaros/perpetuals/leaves/TradingAccount.sol";
import { FeeRecipients } from "@zaros/perpetuals/leaves/FeeRecipients.sol";

// Open Zeppelin dependencies
import { EnumerableSet } from "@openzeppelin/utils/structs/EnumerableSet.sol";
import { EnumerableMap } from "@openzeppelin/utils/structs/EnumerableMap.sol";

// PRB Math dependencies
import { UD60x18 } from "@prb-math/UD60x18.sol";
import { SD59x18 } from "@prb-math/SD59x18.sol";

contract TradingAccountHarness {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    function workaround_getIfMarginCollateralBalanceX18ContainsTheCollateral(
        uint128 tradingAccountId,
        address collateral
    )
        external
        view
        returns (bool)
    {
        TradingAccount.Data storage self = TradingAccount.loadExistingAccountAndVerifySender(tradingAccountId);

        return self.marginCollateralBalanceX18.contains(collateral);
    }

    function workaround_getActiveMarketId(uint128 tradingAccountId, uint128 index) external view returns (uint128) {
        TradingAccount.Data storage self = TradingAccount.load(tradingAccountId);

        return uint128(self.activeMarketsIds.at(index));
    }

    function workaround_getActiveMarketsIdsLength(uint128 tradingAccountId) external view returns (uint256) {
        TradingAccount.Data storage self = TradingAccount.load(tradingAccountId);

        return self.activeMarketsIds.length();
    }

    function workaround_getNonce(uint128 tradingAccountId) external view returns (uint128) {
        TradingAccount.Data storage self = TradingAccount.load(tradingAccountId);

        return self.nonce;
    }

    function workaround_hasOffchainOrderBeenFilled(
        uint128 tradingAccountId,
        bytes32 offchainOrderHash
    )
        external
        view
        returns (bool)
    {
        TradingAccount.Data storage self = TradingAccount.load(tradingAccountId);

        return self.hasOffchainOrderBeenFilled[offchainOrderHash];
    }

    function exposed_TradingAccount_loadExisting(uint128 tradingAccountId) external view {
        TradingAccount.loadExisting(tradingAccountId);
    }

    function exposed_loadExistingAccountAndVerifySender(uint128 tradingAccountId) external view {
        TradingAccount.loadExistingAccountAndVerifySender(tradingAccountId);
    }

    function exposed_validatePositionsLimit(uint128 tradingAccountId) external view {
        TradingAccount.Data storage self = TradingAccount.load(tradingAccountId);
        TradingAccount.validatePositionsLimit(self);
    }

    function exposed_validateMarginRequirements(
        uint128 tradingAccountId,
        UD60x18 requiredMarginUsdX18,
        SD59x18 marginBalanceUsdX18,
        UD60x18 totalFeesUsdX18
    )
        external
        view
    {
        TradingAccount.Data storage self = TradingAccount.load(tradingAccountId);
        TradingAccount.validateMarginRequirement(self, requiredMarginUsdX18, marginBalanceUsdX18, totalFeesUsdX18);
    }

    function exposed_getMarginCollateralBalance(
        uint128 tradingAccountId,
        address collateralType
    )
        external
        view
        returns (UD60x18)
    {
        TradingAccount.Data storage self = TradingAccount.load(tradingAccountId);

        return TradingAccount.getMarginCollateralBalance(self, collateralType);
    }

    function exposed_getEquityUsd(
        uint128 tradingAccountId,
        SD59x18 activePositionsUnrealizedPnlUsdX18
    )
        external
        view
        returns (SD59x18)
    {
        TradingAccount.Data storage self = TradingAccount.load(tradingAccountId);

        return TradingAccount.getEquityUsd(self, activePositionsUnrealizedPnlUsdX18);
    }

    function exposed_getMarginBalanceUsd(
        uint128 tradingAccountId,
        SD59x18 activePositionsUnrealizedPnlUsdX18
    )
        external
        view
        returns (SD59x18)
    {
        TradingAccount.Data storage self = TradingAccount.load(tradingAccountId);

        return TradingAccount.getMarginBalanceUsd(self, activePositionsUnrealizedPnlUsdX18);
    }

    function exposed_getAccountMarginRequirementUsdAndUnrealizedPnlUsd(
        uint128 tradingAccountId,
        uint128 targetMarketId,
        SD59x18 sizeDeltaX18
    )
        external
        view
        returns (UD60x18, UD60x18, SD59x18)
    {
        TradingAccount.Data storage self = TradingAccount.load(tradingAccountId);

        return TradingAccount.getAccountMarginRequirementUsdAndUnrealizedPnlUsd(self, targetMarketId, sizeDeltaX18);
    }

    function exposed_getAccontUnrealizedPnlUsd(uint128 tradingAccountId) external view returns (SD59x18) {
        TradingAccount.Data storage self = TradingAccount.load(tradingAccountId);

        return TradingAccount.getAccountUnrealizedPnlUsd(self);
    }

    function exposed_verifySender(uint128 tradingAccountId) external view {
        TradingAccount.verifySender(tradingAccountId);
    }

    function exposed_isLiquidatable(
        UD60x18 requiredMaintenanceMarginUsdX18,
        SD59x18 marginBalanceUsdX18
    )
        external
        pure
        returns (bool)
    {
        return TradingAccount.isLiquidatable(requiredMaintenanceMarginUsdX18, marginBalanceUsdX18);
    }

    function exposed_create(uint128 tradingAccountId, address owner) external {
        TradingAccount.create(tradingAccountId, owner);
    }

    function exposed_deposit(uint128 tradingAccountId, address collateralType, UD60x18 amount) external {
        TradingAccount.Data storage self = TradingAccount.load(tradingAccountId);

        TradingAccount.deposit(self, collateralType, amount);
    }

    function exposed_withdraw(uint128 tradingAccountId, address collateralType, UD60x18 amount) external {
        TradingAccount.Data storage self = TradingAccount.load(tradingAccountId);

        TradingAccount.withdraw(self, collateralType, amount);
    }

    function exposed_withdrawMarginUsd(
        uint128 tradingAccountId,
        address collateralType,
        UD60x18 marginCollateralPriceUsdX18,
        UD60x18 amountUsdX18,
        address recipient
    )
        external
        returns (UD60x18, bool)
    {
        TradingAccount.Data storage self = TradingAccount.load(tradingAccountId);

        return TradingAccount.withdrawMarginUsd(
            self, collateralType, marginCollateralPriceUsdX18, amountUsdX18, recipient
        );
    }

    function exposed_deductAccountMargin(
        uint128 tradingAccountId,
        FeeRecipients.Data memory feeRecipients,
        UD60x18 pnlUsdX18,
        UD60x18 settlementFeeUsdX18,
        UD60x18 orderFeeUsdX18
    )
        external
        returns (UD60x18)
    {
        TradingAccount.Data storage self = TradingAccount.load(tradingAccountId);

        return TradingAccount.deductAccountMargin(self, feeRecipients, pnlUsdX18, settlementFeeUsdX18, orderFeeUsdX18);
    }

    function exposed_updateActiveMarkets(
        uint128 tradingAccountId,
        uint128 marketId,
        SD59x18 oldPositionSize,
        SD59x18 newPositionSize
    )
        external
    {
        TradingAccount.Data storage self = TradingAccount.load(tradingAccountId);

        TradingAccount.updateActiveMarkets(self, marketId, oldPositionSize, newPositionSize);
    }
}
