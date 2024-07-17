// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { FeeRecipients } from "@zaros/perpetuals/leaves/FeeRecipients.sol";
import { GlobalConfiguration } from "@zaros/perpetuals/leaves/GlobalConfiguration.sol";
import { TradingAccount } from "@zaros/perpetuals/leaves/TradingAccount.sol";
import { PerpMarket } from "@zaros/perpetuals/leaves/PerpMarket.sol";
import { Position } from "@zaros/perpetuals/leaves/Position.sol";
import { MarketOrder } from "@zaros/perpetuals/leaves/MarketOrder.sol";

// Open Zeppelin dependencies
import { EnumerableSet } from "@openzeppelin/utils/structs/EnumerableSet.sol";
import { SafeCast } from "@openzeppelin/utils/math/SafeCast.sol";

// PRB Math dependencies
import { UD60x18, ud60x18, ZERO as UD60x18_ZERO } from "@prb-math/UD60x18.sol";
import { SD59x18, sd59x18, ZERO as SD59x18_ZERO } from "@prb-math/SD59x18.sol";

contract LiquidationBranch {
    using EnumerableSet for EnumerableSet.UintSet;
    using GlobalConfiguration for GlobalConfiguration.Data;
    using TradingAccount for TradingAccount.Data;
    using PerpMarket for PerpMarket.Data;
    using Position for Position.Data;
    using MarketOrder for MarketOrder.Data;
    using SafeCast for uint256;

    event LogLiquidateAccount(
        address indexed keeper,
        uint128 indexed tradingAccountId,
        uint256 amountOfOpenPositions,
        uint256 requiredMaintenanceMarginUsd,
        int256 marginBalanceUsd,
        uint256 liquidatedCollateralUsd,
        uint128 liquidationFeeUsd
    );

    /// @param lowerBound The lower bound of the accounts to check
    /// @param upperBound The upper bound of the accounts to check
    function checkLiquidatableAccounts(
        uint256 lowerBound,
        uint256 upperBound
    )
        external
        view
        returns (uint128[] memory liquidatableAccountsIds)
    {
        // prepare output array size
        liquidatableAccountsIds = new uint128[](upperBound - lowerBound);

        // return if nothing to process
        if (liquidatableAccountsIds.length == 0) return liquidatableAccountsIds;

        // fetch storage slot for global config
        GlobalConfiguration.Data storage globalConfiguration = GlobalConfiguration.load();

        // cache active account ids length
        uint256 cachedAccountsIdsWithActivePositionsLength =
            globalConfiguration.accountsIdsWithActivePositions.length();

        // iterate over active accounts within given bounds
        for (uint256 i = lowerBound; i < upperBound; i++) {
            // break if `i` greater then length of active account ids
            if (i >= cachedAccountsIdsWithActivePositionsLength) break;

            // get the `tradingAccountId` of the current active account
            uint128 tradingAccountId = uint128(globalConfiguration.accountsIdsWithActivePositions.at(i));

            // load that account's leaf (data + functions)
            TradingAccount.Data storage tradingAccount = TradingAccount.loadExisting(tradingAccountId);

            // get that account's required maintenance margin & unrealized PNL
            (, UD60x18 requiredMaintenanceMarginUsdX18, SD59x18 accountTotalUnrealizedPnlUsdX18) =
                tradingAccount.getAccountMarginRequirementUsdAndUnrealizedPnlUsd(0, SD59x18_ZERO);

            // get that account's current margin balance
            SD59x18 marginBalanceUsdX18 = tradingAccount.getMarginBalanceUsd(accountTotalUnrealizedPnlUsdX18);

            // account can be liquidated if requiredMargin > marginBalance
            if (TradingAccount.isLiquidatable(requiredMaintenanceMarginUsdX18, marginBalanceUsdX18)) {
                liquidatableAccountsIds[i] = tradingAccountId;
            }
        }
    }

    struct LiquidationContext {
        UD60x18 liquidationFeeUsdX18;
        uint128 tradingAccountId;
        SD59x18 marginBalanceUsdX18;
        UD60x18 liquidatedCollateralUsdX18;
        uint256[] activeMarketsIds;
        uint128 marketId;
        SD59x18 oldPositionSizeX18;
        SD59x18 liquidationSizeX18;
        UD60x18 markPriceX18;
        SD59x18 fundingRateX18;
        SD59x18 fundingFeePerUnitX18;
        UD60x18 newOpenInterestX18;
        SD59x18 newSkewX18;
    }

    /// @param accountsIds The list of accounts to liquidate
    function liquidateAccounts(uint128[] calldata accountsIds) external {
        // return if no input accounts to process
        if (accountsIds.length == 0) return;

        // fetch storage slot for global config
        GlobalConfiguration.Data storage globalConfiguration = GlobalConfiguration.load();

        // only authorized liquidators are able to liquidate
        if (!globalConfiguration.isLiquidatorEnabled[msg.sender]) {
            revert Errors.LiquidatorNotRegistered(msg.sender);
        }

        // working data
        LiquidationContext memory ctx;

        // load liquidation fee from global config; will be passed in as `settlementFeeUsdX18`
        // to `TradingAccount::deductAccountMargin`. The user being liquidated has to pay
        // this liquidation fee as a "settlement fee"
        ctx.liquidationFeeUsdX18 = ud60x18(globalConfiguration.liquidationFeeUsdX18);

        // iterate over every account being liquidated; intentionally not caching
        // length as reading from calldata is faster
        for (uint256 i; i < accountsIds.length; i++) {
            // store current accountId being liquidated in working data
            ctx.tradingAccountId = accountsIds[i];

            // sanity check for non-sensical accountId; should never be true
            if (ctx.tradingAccountId == 0) continue;

            // load account's leaf (data + functions)
            TradingAccount.Data storage tradingAccount = TradingAccount.loadExisting(ctx.tradingAccountId);

            // get account's required maintenance margin & unrealized PNL
            (, UD60x18 requiredMaintenanceMarginUsdX18, SD59x18 accountTotalUnrealizedPnlUsdX18) =
                tradingAccount.getAccountMarginRequirementUsdAndUnrealizedPnlUsd(0, SD59x18_ZERO);

            // get then save margin balance into working data
            ctx.marginBalanceUsdX18 = tradingAccount.getMarginBalanceUsd(accountTotalUnrealizedPnlUsdX18);

            // if account is not liquidatable, skip to next account
            // account is liquidatable if requiredMaintenanceMarginUsdX18 > ctx.marginBalanceUsdX18
            if (!TradingAccount.isLiquidatable(requiredMaintenanceMarginUsdX18, ctx.marginBalanceUsdX18)) {
                continue;
            }

            // deduct maintenance margin from the account's collateral
            // settlementFee = liquidationFee
            ctx.liquidatedCollateralUsdX18 = tradingAccount.deductAccountMargin({
                feeRecipients: FeeRecipients.Data({
                    marginCollateralRecipient: globalConfiguration.marginCollateralRecipient,
                    orderFeeRecipient: address(0),
                    settlementFeeRecipient: globalConfiguration.liquidationFeeRecipient
                }),
                pnlUsdX18: requiredMaintenanceMarginUsdX18,
                orderFeeUsdX18: UD60x18_ZERO,
                settlementFeeUsdX18: ctx.liquidationFeeUsdX18
            });

            // clear pending order for account being liquidated
            MarketOrder.load(ctx.tradingAccountId).clear();

            // copy active market ids for account being liquidated
            ctx.activeMarketsIds = tradingAccount.activeMarketsIds.values();

            // iterate over memory copy of active market ids
            // intentionally not caching length as expected size < 3 in most cases
            for (uint256 j; j < ctx.activeMarketsIds.length; j++) {
                // load current active market id into working data
                ctx.marketId = ctx.activeMarketsIds[j].toUint128();

                // fetch storage slot for perp market
                PerpMarket.Data storage perpMarket = PerpMarket.load(ctx.marketId);

                // load position data for user being liquidated in this market
                Position.Data storage position = Position.load(ctx.tradingAccountId, ctx.marketId);

                // save open position size
                ctx.oldPositionSizeX18 = sd59x18(position.size);

                // save inverted sign of open position size to prepare for closing the position
                ctx.liquidationSizeX18 = -ctx.oldPositionSizeX18;

                // calculate price impact of open position being closed
                ctx.markPriceX18 = perpMarket.getMarkPrice(ctx.liquidationSizeX18, perpMarket.getIndexPrice());

                // get current funding rates
                ctx.fundingRateX18 = perpMarket.getCurrentFundingRate();
                ctx.fundingFeePerUnitX18 = perpMarket.getNextFundingFeePerUnit(ctx.fundingRateX18, ctx.markPriceX18);

                // update funding rates for this perpetual market
                perpMarket.updateFunding(ctx.fundingRateX18, ctx.fundingFeePerUnitX18);

                // reset the position
                position.clear();

                // update account's active markets; this calls EnumerableSet::remove which
                // is why we are iterating over a memory copy of the trader's active markets
                tradingAccount.updateActiveMarkets(ctx.marketId, ctx.oldPositionSizeX18, SD59x18_ZERO);

                // update perp market's open interest and skew; we don't enforce ipen
                // interest and skew caps during liquidations as:
                // 1) open interest and skew are both decreased by liquidations
                // 2) we don't want liquidation to be DoS'd in case somehow those cap
                //    checks would fail
                perpMarket.updateOpenInterest(ctx.newOpenInterestX18, ctx.newSkewX18);
            }

            emit LogLiquidateAccount(
                msg.sender,
                ctx.tradingAccountId,
                ctx.activeMarketsIds.length,
                requiredMaintenanceMarginUsdX18.intoUint256(),
                ctx.marginBalanceUsdX18.intoInt256(),
                ctx.liquidatedCollateralUsdX18.intoUint256(),
                ctx.liquidationFeeUsdX18.intoUint128()
            );
        }
    }
}
