// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { MarketOrder } from "@zaros/perpetuals/leaves/MarketOrder.sol";
import { OrderFees } from "@zaros/perpetuals/leaves/OrderFees.sol";
import { TradingAccount } from "@zaros/perpetuals/leaves/TradingAccount.sol";
import { GlobalConfiguration } from "@zaros/perpetuals/leaves/GlobalConfiguration.sol";
import { PerpMarket } from "@zaros/perpetuals/leaves/PerpMarket.sol";
import { Position } from "@zaros/perpetuals/leaves/Position.sol";
import { SettlementConfiguration } from "@zaros/perpetuals/leaves/SettlementConfiguration.sol";

// Open Zeppelin dependencies
import { IERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { SafeCast } from "@openzeppelin/utils/math/SafeCast.sol";
import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";
import { SD59x18, sd59x18, ZERO as SD59x18_ZERO } from "@prb-math/SD59x18.sol";

contract OrderBranch {
    using SafeCast for uint256;
    using SafeERC20 for IERC20;
    using MarketOrder for MarketOrder.Data;
    using TradingAccount for TradingAccount.Data;
    using GlobalConfiguration for GlobalConfiguration.Data;
    using PerpMarket for PerpMarket.Data;
    using Position for Position.Data;
    using SettlementConfiguration for SettlementConfiguration.Data;

    /// @notice Emitted when a market order is created.
    /// @param sender The account that created the market order.
    /// @param tradingAccountId The trading account id.
    /// @param marketId The perp market id.
    /// @param marketOrder The market order data.
    event LogCreateMarketOrder(
        address indexed sender,
        uint128 indexed tradingAccountId,
        uint128 indexed marketId,
        MarketOrder.Data marketOrder
    );
    /// @notice Emitted when all offchain orders are cancelled.
    /// @param sender The account that cancelled all offchain orders.
    /// @param tradingAccountId The trading account id.
    /// @param newNonce The new nonce value.
    event LogCancelAllOffchainOrders(address indexed sender, uint128 indexed tradingAccountId, uint128 newNonce);
    /// @notice Emitted when a market order is cancelled.
    /// @param sender The account that cancelled the market order.
    /// @param tradingAccountId The trading account id.
    event LogCancelMarketOrder(address indexed sender, uint128 indexed tradingAccountId);

    /// @param marketId The perp market id.
    /// @return The order fees for the given market.
    function getConfiguredOrderFees(uint128 marketId) external view returns (OrderFees.Data memory) {
        return PerpMarket.load(marketId).configuration.orderFees;
    }

    struct SimulateTradeContext {
        SD59x18 sizeDeltaX18;
        SD59x18 accountTotalUnrealizedPnlUsdX18;
        UD60x18 previousRequiredMaintenanceMarginUsdX18;
        SD59x18 newPositionSizeX18;
    }

    /// @notice Simulates the settlement costs and validity of a given order.
    /// @dev Reverts if there's not enough margin to cover the trade.
    /// @param tradingAccountId The trading account id.
    /// @param marketId The perp market id.
    /// @param settlementConfigurationId The perp market settlement configuration id.
    /// @param sizeDelta The size delta of the order.
    /// @return marginBalanceUsdX18 The given account's current margin balance.
    /// @return requiredInitialMarginUsdX18 The required initial margin to settle the given trade.
    /// @return requiredMaintenanceMarginUsdX18 The required maintenance margin to settle the given trade.
    /// @return orderFeeUsdX18 The order fee in USD.
    /// @return settlementFeeUsdX18 The settlement fee in USD.
    /// @return fillPriceX18 The fill price quote.
    function simulateTrade(
        uint128 tradingAccountId,
        uint128 marketId,
        uint128 settlementConfigurationId,
        int128 sizeDelta
    )
        public
        view
        returns (
            SD59x18 marginBalanceUsdX18,
            UD60x18 requiredInitialMarginUsdX18,
            UD60x18 requiredMaintenanceMarginUsdX18,
            UD60x18 orderFeeUsdX18,
            UD60x18 settlementFeeUsdX18,
            UD60x18 fillPriceX18
        )
    {
        // load existing trading account; reverts for non-existent account
        TradingAccount.Data storage tradingAccount = TradingAccount.loadExisting(tradingAccountId);

        // fetch storage slot for perp market
        PerpMarket.Data storage perpMarket = PerpMarket.load(marketId);

        // fetch storage slot for perp market's settlement config
        SettlementConfiguration.Data storage settlementConfiguration =
            SettlementConfiguration.load(marketId, settlementConfigurationId);

        // working data
        SimulateTradeContext memory ctx;

        // int128 -> SD59x18
        ctx.sizeDeltaX18 = sd59x18(sizeDelta);

        // calculate & output execution price
        fillPriceX18 = perpMarket.getMarkPrice(ctx.sizeDeltaX18, perpMarket.getIndexPrice());

        // calculate & output order fee
        orderFeeUsdX18 = perpMarket.getOrderFeeUsd(ctx.sizeDeltaX18, fillPriceX18);

        // output settlement fee uint80 -> uint256 -> UD60x18
        settlementFeeUsdX18 = ud60x18(uint256(settlementConfiguration.fee));

        // calculate & output required initial & maintenance margin for the simulated trade
        // and account's unrealized PNL
        (requiredInitialMarginUsdX18, requiredMaintenanceMarginUsdX18, ctx.accountTotalUnrealizedPnlUsdX18) =
            tradingAccount.getAccountMarginRequirementUsdAndUnrealizedPnlUsd(marketId, ctx.sizeDeltaX18);

        // use unrealized PNL to calculate & output account's margin balance
        marginBalanceUsdX18 = tradingAccount.getMarginBalanceUsd(ctx.accountTotalUnrealizedPnlUsdX18);
        {
            // get account's current required margin maintenance (before this trade)
            (, ctx.previousRequiredMaintenanceMarginUsdX18,) =
                tradingAccount.getAccountMarginRequirementUsdAndUnrealizedPnlUsd(0, SD59x18_ZERO);

            // prevent liquidatable accounts from trading
            if (TradingAccount.isLiquidatable(ctx.previousRequiredMaintenanceMarginUsdX18, marginBalanceUsdX18)) {
                revert Errors.AccountIsLiquidatable(tradingAccountId);
            }
        }
        {
            // fetch storage slot for account's potential existing position in this market
            Position.Data storage position = Position.load(tradingAccountId, marketId);

            // calculate and store new position size in working data
            ctx.newPositionSizeX18 = sd59x18(position.size).add(ctx.sizeDeltaX18);

            // revert if
            // 1) this trade doesn't close an existing open position AND
            // 2) abs(newPositionSize) is smaller than minimum position size
            // this enforces a minimum position size both for new trades but
            // also for existing trades which have their position size reduced
            if (
                !ctx.newPositionSizeX18.isZero()
                    && ctx.newPositionSizeX18.abs().lt(sd59x18(int256(uint256(perpMarket.configuration.minTradeSizeX18))))
            ) {
                revert Errors.NewPositionSizeTooSmall();
            }
        }
    }

    /// @param marketId The perp market id.
    /// @param sizeDelta The size delta of the order.
    /// @param settlementConfigurationId The perp market settlement configuration id.
    /// @return initialMarginUsdX18 The initial margin requirement for the given trade.
    /// @return maintenanceMarginUsdX18 The maintenance margin requirement for the given trade.
    /// @return orderFeeUsdX18 The order fee in USD.
    /// @return settlementFeeUsdX18 The settlement fee in USD.
    function getMarginRequirementForTrade(
        uint128 marketId,
        int128 sizeDelta,
        uint128 settlementConfigurationId
    )
        external
        view
        returns (
            UD60x18 initialMarginUsdX18,
            UD60x18 maintenanceMarginUsdX18,
            UD60x18 orderFeeUsdX18,
            UD60x18 settlementFeeUsdX18
        )
    {
        // fetch storage slot for perp market
        PerpMarket.Data storage perpMarket = PerpMarket.load(marketId);

        // fetch storage slot for perp market's settlement config
        SettlementConfiguration.Data storage settlementConfiguration =
            SettlementConfiguration.load(marketId, settlementConfigurationId);

        // fetch index price for perp market
        UD60x18 indexPriceX18 = perpMarket.getIndexPrice();

        // cache size delta as SD59x18
        SD59x18 sizeDeltaX18 = sd59x18(sizeDelta);

        // calculate & output execution price
        UD60x18 markPriceX18 = perpMarket.getMarkPrice(sizeDeltaX18, indexPriceX18);

        // calculate order value
        UD60x18 orderValueX18 = markPriceX18.mul(sizeDeltaX18.abs().intoUD60x18());

        // calculate & output initial & maintenance margin requirements
        initialMarginUsdX18 = orderValueX18.mul(ud60x18(perpMarket.configuration.initialMarginRateX18));
        maintenanceMarginUsdX18 = orderValueX18.mul(ud60x18(perpMarket.configuration.maintenanceMarginRateX18));

        // calculate & output order and settlement fees
        orderFeeUsdX18 = perpMarket.getOrderFeeUsd(sizeDeltaX18, markPriceX18);
        settlementFeeUsdX18 = ud60x18(uint256(settlementConfiguration.fee));
    }

    /// @param tradingAccountId The trading account id to get the active market
    function getActiveMarketOrder(uint128 tradingAccountId)
        external
        pure
        returns (MarketOrder.Data memory marketOrder)
    {
        marketOrder = MarketOrder.load(tradingAccountId);
    }

    /// @param tradingAccountId The trading account id creating the market order
    /// @param marketId The perp market id
    /// @param sizeDelta The size delta of the order
    struct CreateMarketOrderParams {
        uint128 tradingAccountId;
        uint128 marketId;
        int128 sizeDelta;
    }

    struct CreateMarketOrderContext {
        SD59x18 marginBalanceUsdX18;
        SD59x18 sizeDeltaX18;
        SD59x18 positionSizeX18;
        UD60x18 requiredInitialMarginUsdX18;
        UD60x18 requiredMaintenanceMarginUsdX18;
        UD60x18 orderFeeUsdX18;
        UD60x18 settlementFeeUsdX18;
        UD60x18 requiredMarginUsdX18;
        bool isIncreasing;
        bool shouldUseMaintenanceMargin;
        bool isMarketWithActivePosition;
    }

    /// @notice Creates a market order for the given trading account and market ids.
    /// @dev See {CreateMarketOrderParams}.
    function createMarketOrder(CreateMarketOrderParams calldata params) external {
        // working data
        CreateMarketOrderContext memory ctx;

        // revert for non-sensical zero size order
        if (params.sizeDelta == 0) {
            revert Errors.ZeroInput("sizeDelta");
        }

        // int128 -> SD59x18
        ctx.sizeDeltaX18 = sd59x18(params.sizeDelta);

        // fetch storage slot for global config
        GlobalConfiguration.Data storage globalConfiguration = GlobalConfiguration.load();

        // fetch storage slot for perp market's settlement config
        SettlementConfiguration.Data storage settlementConfiguration =
            SettlementConfiguration.load(params.marketId, SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID);

        // determine whether position is being increased or not
        ctx.isIncreasing = Position.isIncreasing(params.tradingAccountId, params.marketId, params.sizeDelta);

        // both markets and settlement can be disabled, however when this happens we want to:
        // 1) allow open positions not subject to liquidation to decrease their size or close
        // 2) prevent new positions from being opened & existing positions being increased
        //
        // the idea is to prevent a state where traders have open positions but are unable
        // to reduce size or close even though they can still be liquidated; such a state
        // would severly disadvantage traders
        if (ctx.isIncreasing) {
            // both checks revert if disabled
            globalConfiguration.checkMarketIsEnabled(params.marketId);
            settlementConfiguration.checkIsSettlementEnabled();
        }

        // load existing trading account; reverts for non-existent account
        // enforces `msg.sender == owner` so only account owner can place trades
        TradingAccount.Data storage tradingAccount =
            TradingAccount.loadExistingAccountAndVerifySender(params.tradingAccountId);

        // find if account has active position in this market
        ctx.isMarketWithActivePosition = tradingAccount.isMarketWithActivePosition(params.marketId);

        // if the account doesn't have an active position in this market then
        // this trade is opening a new active position in a new market, hence
        // revert if this new position would put the account over the maximum
        // number of open positions
        if (!ctx.isMarketWithActivePosition) {
            tradingAccount.validatePositionsLimit();
        }

        // fetch storage slot for perp market
        PerpMarket.Data storage perpMarket = PerpMarket.load(params.marketId);

        // enforce minimum trade size for this market
        perpMarket.checkTradeSize(ctx.sizeDeltaX18);

        // fetch storage slot for account's potential existing position in this market
        Position.Data storage position = Position.load(params.tradingAccountId, params.marketId);
        // int128 -> SD59x18
        ctx.positionSizeX18 = sd59x18(position.size);

        // enforce open interest and skew limits for target market
        perpMarket.checkOpenInterestLimits(
            ctx.sizeDeltaX18, ctx.positionSizeX18, ctx.positionSizeX18.add(ctx.sizeDeltaX18)
        );

        // fetch storage slot for trader's potential pending order
        MarketOrder.Data storage marketOrder = MarketOrder.load(params.tradingAccountId);

        (
            ctx.marginBalanceUsdX18,
            ctx.requiredInitialMarginUsdX18,
            ctx.requiredMaintenanceMarginUsdX18,
            ctx.orderFeeUsdX18,
            ctx.settlementFeeUsdX18,
        ) = simulateTrade({
            tradingAccountId: params.tradingAccountId,
            marketId: params.marketId,
            settlementConfigurationId: SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
            sizeDelta: params.sizeDelta
        });

        // check maintenance margin if:
        // 1) position is not increasing AND
        // 2) existing position is being decreased in size
        //
        // when a position is under the higher initial margin requirement but over the
        // lower maintenance margin requirement, we want to allow the trader to decrease
        // their losing position size before they become subject to liquidation
        //
        // but if the trader is opening a new position or increasing the size
        // of their existing position we want to ensure they satisfy the higher
        // initial margin requirement
        ctx.shouldUseMaintenanceMargin = !Position.isIncreasing(params.tradingAccountId, params.marketId, params.sizeDelta)
            && ctx.isMarketWithActivePosition;

        ctx.requiredMarginUsdX18 =
            ctx.shouldUseMaintenanceMargin ? ctx.requiredMaintenanceMarginUsdX18 : ctx.requiredInitialMarginUsdX18;

        // reverts if the trader can't satisfy the appropriate margin requirement
        tradingAccount.validateMarginRequirement(
            ctx.requiredMarginUsdX18, ctx.marginBalanceUsdX18, ctx.orderFeeUsdX18.add(ctx.settlementFeeUsdX18)
        );

        // reverts if a trader has a pending order and that pending order hasn't
        // existed for the minimum order lifetime
        marketOrder.checkPendingOrder();

        // store pending order details
        marketOrder.update({ marketId: params.marketId, sizeDelta: params.sizeDelta });

        emit LogCreateMarketOrder(msg.sender, params.tradingAccountId, params.marketId, marketOrder);
    }

    /// @notice Cancels all active offchain orders.
    /// @dev Reverts if the sender is not the trading account owner or it does not exist.
    /// @dev By increasing the `tradingAccount.nonce` value, all offchain orders signed with the previous nonce won't
    /// be able to be filled.
    /// @dev If for some reason the trading account owner has signed offchain orders with nonce values higher than the
    /// current nonce, and the new nonce value matches those values, the offchain orders will become fillable. Offchain
    /// actors must enforce signing orders with the latest nonce value.
    /// @param tradingAccountId The trading account id.
    function cancelAllOffchainOrders(uint128 tradingAccountId) external {
        // load existing trading account; reverts for non-existent account
        // enforces `msg.sender == owner` so only account owner can cancel
        // pendin orders.
        TradingAccount.Data storage tradingAccount =
            TradingAccount.loadExistingAccountAndVerifySender(tradingAccountId);

        // bump the nonce value, which will invalidate all offchain orders signed with the previous nonce
        unchecked {
            tradingAccount.nonce++;
        }

        emit LogCancelAllOffchainOrders(msg.sender, tradingAccountId, tradingAccount.nonce);
    }

    /// @notice Cancels an active market order.
    /// @dev Reverts if the sender is not the trading account owner, if it doesn't exist, or if there is no active
    /// market order for the given trading account.
    /// @param tradingAccountId The trading account id.
    function cancelMarketOrder(uint128 tradingAccountId) external {
        // load existing trading account; reverts for non-existent account
        // enforces `msg.sender == owner` so only account owner can cancel
        // pending orders
        TradingAccount.loadExistingAccountAndVerifySender(tradingAccountId);

        // load trader's pending order; reverts if no pending order
        MarketOrder.Data storage marketOrder = MarketOrder.loadExisting(tradingAccountId);

        // reverts if a trader has a pending order and that pending order hasn't
        // existed for the minimum order lifetime; pending orders can't be cancelled
        // until they have existed for the minimum order lifetime
        marketOrder.checkPendingOrder();

        // reset pending order details
        marketOrder.clear();

        emit LogCancelMarketOrder(msg.sender, tradingAccountId);
    }
}
