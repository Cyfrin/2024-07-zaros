// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { LimitedMintingERC20 } from "testnet/LimitedMintingERC20.sol";
import { Constants } from "@zaros/utils/Constants.sol";
import { Errors } from "@zaros/utils/Errors.sol";
import { OffchainOrder } from "@zaros/perpetuals/leaves/OffchainOrder.sol";
import { MarketOrder } from "@zaros/perpetuals/leaves/MarketOrder.sol";
import { TradingAccount } from "@zaros/perpetuals/leaves/TradingAccount.sol";
import { FeeRecipients } from "@zaros/perpetuals/leaves/FeeRecipients.sol";
import { GlobalConfiguration } from "@zaros/perpetuals/leaves/GlobalConfiguration.sol";
import { PerpMarket } from "@zaros/perpetuals/leaves/PerpMarket.sol";
import { Position } from "@zaros/perpetuals/leaves/Position.sol";
import { SettlementConfiguration } from "@zaros/perpetuals/leaves/SettlementConfiguration.sol";

// Open Zeppelin dependencies
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EnumerableSet } from "@openzeppelin/utils/structs/EnumerableSet.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { SafeCast } from "@openzeppelin/utils/math/SafeCast.sol";

// Open Zeppelin Upgradeable dependencies
import { EIP712Upgradeable } from "@openzeppelin-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

// PRB Math dependencies
import { UD60x18, ud60x18, ZERO as UD60x18_ZERO } from "@prb-math/UD60x18.sol";
import { SD59x18, sd59x18, ZERO as SD59x18_ZERO, unary } from "@prb-math/SD59x18.sol";

contract SettlementBranch is EIP712Upgradeable {
    using EnumerableSet for EnumerableSet.UintSet;
    using GlobalConfiguration for GlobalConfiguration.Data;
    using MarketOrder for MarketOrder.Data;
    using TradingAccount for TradingAccount.Data;
    using PerpMarket for PerpMarket.Data;
    using Position for Position.Data;
    using SafeCast for uint256;
    using SafeCast for int256;
    using SafeERC20 for IERC20;
    using SettlementConfiguration for SettlementConfiguration.Data;

    constructor() {
        _disableInitializers();
    }

    /// @notice Emitted when a order is filled.
    /// @param sender The `msg.sender` address.
    /// @param tradingAccountId The trading account id that created the order.
    /// @param marketId The id of the perp market being settled.
    /// @param sizeDelta The size delta of the order.
    /// @param fillPrice The price at which the order was filled.
    /// @param orderFeeUsd The order fee in USD.
    /// @param settlementFeeUsd The settlement fee in USD.
    /// @param pnl The realized profit or loss.
    /// @param fundingFeePerUnit The funding fee per unit of the market being settled.
    event LogFillOrder(
        address indexed sender,
        uint128 indexed tradingAccountId,
        uint128 indexed marketId,
        int256 sizeDelta,
        uint256 fillPrice,
        uint256 orderFeeUsd,
        uint256 settlementFeeUsd,
        int256 pnl,
        int256 fundingFeePerUnit
    );

    modifier onlyMarketOrderKeeper(uint128 marketId) {
        SettlementConfiguration.Data storage settlementConfiguration =
            SettlementConfiguration.load(marketId, SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID);

        _requireIsKeeper(msg.sender, settlementConfiguration.keeper);
        _;
    }

    modifier onlyOffchainOrdersKeeper(uint128 marketId) {
        SettlementConfiguration.Data storage settlementConfiguration =
            SettlementConfiguration.load(marketId, SettlementConfiguration.OFFCHAIN_ORDERS_CONFIGURATION_ID);

        _requireIsKeeper(msg.sender, settlementConfiguration.keeper);
        _;
    }

    /// @dev {SettlementBranch}  UUPS initializer.
    function initialize() external initializer {
        __EIP712_init(Constants.ZAROS_DOMAIN_NAME, Constants.ZAROS_DOMAIN_VERSION);
    }

    /// @notice Returns the EIP-712 domain separator.
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    struct FillMarketOrder_Context {
        UD60x18 bidX18;
        UD60x18 askX18;
        SD59x18 sizeDeltaX18;
        bool isBuyOrder;
        UD60x18 indexPriceX18;
        UD60x18 fillPriceX18;
    }

    /// @notice Fills a pending market order created by the given trading account id at a given market id.
    /// @param tradingAccountId The trading account id.
    /// @param marketId The perp market id.
    /// @param priceData The price data of market order.
    function fillMarketOrder(
        uint128 tradingAccountId,
        uint128 marketId,
        bytes calldata priceData
    )
        external
        onlyMarketOrderKeeper(marketId)
    {
        // working data
        FillMarketOrder_Context memory ctx;

        // fetch storage slot for perp market's market order config
        SettlementConfiguration.Data storage settlementConfiguration =
            SettlementConfiguration.load(marketId, SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID);

        // load trader's pending order; reverts if no pending order
        MarketOrder.Data storage marketOrder = MarketOrder.loadExisting(tradingAccountId);

        // enforce that keeper is filling the order for the correct marketId
        if (marketId != marketOrder.marketId) {
            revert Errors.OrderMarketIdMismatch(marketId, marketOrder.marketId);
        }

        // fetch storage slot for perp market
        PerpMarket.Data storage perpMarket = PerpMarket.load(marketId);

        // fetch storage slot for global config
        GlobalConfiguration.Data storage globalConfiguration = GlobalConfiguration.load();

        // verifies provided price data following the configured settlement strategy
        // returning the bid and ask prices
        (ctx.bidX18, ctx.askX18) =
            settlementConfiguration.verifyOffchainPrice(priceData, globalConfiguration.maxVerificationDelay);

        // cache the order's size delta
        ctx.sizeDeltaX18 = sd59x18(marketOrder.sizeDelta);

        // cache the order side
        ctx.isBuyOrder = ctx.sizeDeltaX18.gt(SD59x18_ZERO);

        //  buy order -> match against the ask price
        // sell order -> match against the bid price
        ctx.indexPriceX18 = ctx.isBuyOrder ? ctx.askX18 : ctx.bidX18;

        // verify the provided price data against the verifier and ensure it's valid, then get the mark price
        // based on the returned index price.
        ctx.fillPriceX18 = perpMarket.getMarkPrice(ctx.sizeDeltaX18, ctx.indexPriceX18);

        // perform the fill
        _fillOrder(
            tradingAccountId,
            marketId,
            SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
            ctx.sizeDeltaX18,
            ctx.fillPriceX18
        );

        // reset pending order details
        marketOrder.clear();
    }

    struct FillOffchainOrders_Context {
        UD60x18 bidX18;
        UD60x18 askX18;
        UD60x18 indexPriceX18;
        UD60x18 fillPriceX18;
        bytes32 structHash;
        OffchainOrder.Data offchainOrder;
        address signer;
        bool isFillPriceValid;
        bool isBuyOrder;
    }

    /// @notice Fills pending, eligible offchain offchain orders targeting the given market id.
    /// @dev If a trading account id owner transfers their account to another address, all offchain orders will be
    /// considered cancelled.
    /// @param marketId The perp market id.
    /// @param offchainOrders The array of signed custom orders.
    /// @param priceData The price data of custom orders.
    function fillOffchainOrders(
        uint128 marketId,
        OffchainOrder.Data[] calldata offchainOrders,
        bytes calldata priceData
    )
        external
        onlyOffchainOrdersKeeper(marketId)
    {
        // working data
        FillOffchainOrders_Context memory ctx;

        // fetch storage slot for perp market's offchain order config
        SettlementConfiguration.Data storage settlementConfiguration =
            SettlementConfiguration.load(marketId, SettlementConfiguration.OFFCHAIN_ORDERS_CONFIGURATION_ID);

        // fetch storage slot for perp market
        PerpMarket.Data storage perpMarket = PerpMarket.load(marketId);

        // fetch storage slot for global config
        GlobalConfiguration.Data storage globalConfiguration = GlobalConfiguration.load();

        // verifies provided price data following the configured settlement strategy
        // returning the bid and ask prices
        (ctx.bidX18, ctx.askX18) =
            settlementConfiguration.verifyOffchainPrice(priceData, globalConfiguration.maxVerificationDelay);

        // iterate through off-chain orders; intentionally not caching
        // length as reading from calldata is faster
        for (uint256 i; i < offchainOrders.length; i++) {
            ctx.offchainOrder = offchainOrders[i];

            // enforce size > 0
            if (ctx.offchainOrder.sizeDelta == 0) {
                revert Errors.ZeroInput("offchainOrder.sizeDelta");
            }

            // load existing trading account; reverts for non-existent account
            TradingAccount.Data storage tradingAccount =
                TradingAccount.loadExisting(ctx.offchainOrder.tradingAccountId);

            // enforce that keeper is filling the order for the correct marketId
            if (marketId != ctx.offchainOrder.marketId) {
                revert Errors.OrderMarketIdMismatch(marketId, ctx.offchainOrder.marketId);
            }

            // First we check if the nonce is valid, as a first measure to protect from replay attacks, according to
            // the offchain order's type (each type may have its own business logic).
            // e.g TP/SL must increase the nonce in order to prevent older limit orders from being filled.
            // NOTE: Since the nonce isn't always increased, we also need to store the typed data hash containing the
            // 256-bit salt value to fully prevent replay attacks.
            if (ctx.offchainOrder.nonce != tradingAccount.nonce) {
                revert Errors.InvalidSignedNonce(tradingAccount.nonce, ctx.offchainOrder.nonce);
            }

            ctx.structHash = keccak256(
                abi.encode(
                    Constants.CREATE_OFFCHAIN_ORDER_TYPEHASH,
                    ctx.offchainOrder.tradingAccountId,
                    ctx.offchainOrder.marketId,
                    ctx.offchainOrder.sizeDelta,
                    ctx.offchainOrder.targetPrice,
                    ctx.offchainOrder.shouldIncreaseNonce,
                    ctx.offchainOrder.nonce,
                    ctx.offchainOrder.salt
                )
            );

            // If the offchain order has already been filled, revert.
            // we store `ctx.hash`, and expect each order signed by the user to provide a unique salt so that filled
            // orders can't be replayed regardless of the account's nonce.
            if (tradingAccount.hasOffchainOrderBeenFilled[ctx.structHash]) {
                revert Errors.OrderAlreadyFilled(ctx.offchainOrder.tradingAccountId, ctx.offchainOrder.salt);
            }

            // `ecrecover`s the order signer.
            ctx.signer = ECDSA.recover(
                _hashTypedDataV4(ctx.structHash), ctx.offchainOrder.v, ctx.offchainOrder.r, ctx.offchainOrder.s
            );

            // ensure the signer is the owner of the trading account, otherwise revert.
            // NOTE: If an account's owner transfers to another address, this will fail. Therefore, clients must
            // cancel all users offchain orders in that scenario.
            if (ctx.signer != tradingAccount.owner) {
                revert Errors.InvalidOrderSigner(ctx.signer, tradingAccount.owner);
            }

            // cache the order side
            ctx.isBuyOrder = ctx.offchainOrder.sizeDelta > 0;

            //  buy order -> match against the ask price
            // sell order -> match against the bid price
            ctx.indexPriceX18 = ctx.isBuyOrder ? ctx.askX18 : ctx.bidX18;

            // verify the provided price data against the verifier and ensure it's valid, then get the mark price
            // based on the returned index price.
            ctx.fillPriceX18 = perpMarket.getMarkPrice(sd59x18(ctx.offchainOrder.sizeDelta), ctx.indexPriceX18);

            // if the order increases the trading account's position (buy order), the fill price must be less than or
            // equal to the target price, if it decreases the trading account's position (sell order), the fill price
            // must be greater than or equal to the target price.
            ctx.isFillPriceValid = (ctx.isBuyOrder && ctx.offchainOrder.targetPrice <= ctx.fillPriceX18.intoUint256())
                || (!ctx.isBuyOrder && ctx.offchainOrder.targetPrice >= ctx.fillPriceX18.intoUint256());

            // we don't revert here because we want to continue filling other orders.
            if (!ctx.isFillPriceValid) {
                continue;
            }

            // account state updates start here

            // increase the trading account nonce if the order's flag is true.
            if (ctx.offchainOrder.shouldIncreaseNonce) {
                unchecked {
                    tradingAccount.nonce++;
                }
            }

            // mark the offchain order as filled.
            // we store the struct hash to be marked as filled.
            tradingAccount.hasOffchainOrderBeenFilled[ctx.structHash] = true;

            // fill the offchain order.
            _fillOrder(
                ctx.offchainOrder.tradingAccountId,
                marketId,
                SettlementConfiguration.OFFCHAIN_ORDERS_CONFIGURATION_ID,
                sd59x18(ctx.offchainOrder.sizeDelta),
                ctx.fillPriceX18
            );
        }
    }

    struct FillOrderContext {
        uint128 marketId;
        uint128 tradingAccountId;
        Position.Data newPosition;
        UD60x18 orderFeeUsdX18;
        UD60x18 settlementFeeUsdX18;
        UD60x18 newOpenInterestX18;
        UD60x18 requiredMarginUsdX18;
        UD60x18 marginToAddX18;
        SD59x18 oldPositionSizeX18;
        SD59x18 newPositionSizeX18;
        SD59x18 pnlUsdX18;
        SD59x18 fundingFeePerUnitX18;
        SD59x18 fundingRateX18;
        SD59x18 newSkewX18;
        address usdToken;
        bool shouldUseMaintenanceMargin;
        bool isIncreasing;
    }

    /// @param tradingAccountId The trading account id.
    /// @param marketId The perp market id.
    /// @param settlementConfigurationId The perp market settlement configuration id.
    /// @param sizeDeltaX18 The size delta of the order normalized to 18 decimals.
    /// @param fillPriceX18 The fill price of the order normalized to 18 decimals.
    function _fillOrder(
        uint128 tradingAccountId,
        uint128 marketId,
        uint128 settlementConfigurationId,
        SD59x18 sizeDeltaX18,
        UD60x18 fillPriceX18
    )
        internal
        virtual
    {
        // working data
        FillOrderContext memory ctx;

        // fetch storage slot for global config
        GlobalConfiguration.Data storage globalConfiguration = GlobalConfiguration.load();

        // fetch storage slot for perp market's settlement config
        SettlementConfiguration.Data storage settlementConfiguration =
            SettlementConfiguration.load(marketId, settlementConfigurationId);

        // cache settlement token
        ctx.usdToken = globalConfiguration.usdToken;

        // determine whether position is being increased or not
        ctx.isIncreasing = Position.isIncreasing(tradingAccountId, marketId, sizeDeltaX18.intoInt256().toInt128());

        // both markets and settlement can be disabled, however when this happens we want to:
        // 1) allow open positions not subject to liquidation to decrease their size or close
        // 2) prevent new positions from being opened & existing positions being increased
        //
        // the idea is to prevent a state where traders have open positions but are unable
        // to reduce size or close even though they can still be liquidated; such a state
        // would severly disadvantage traders
        if (ctx.isIncreasing) {
            // both checks revert if disabled
            globalConfiguration.checkMarketIsEnabled(marketId);
            settlementConfiguration.checkIsSettlementEnabled();
        }

        // load existing trading account; reverts for non-existent account
        TradingAccount.Data storage tradingAccount = TradingAccount.loadExisting(tradingAccountId);

        // fetch storage slot for perp market
        PerpMarket.Data storage perpMarket = PerpMarket.load(marketId);

        // enforce minimum trade size
        perpMarket.checkTradeSize(sizeDeltaX18);

        // get funding rates for this perp market
        ctx.fundingRateX18 = perpMarket.getCurrentFundingRate();
        ctx.fundingFeePerUnitX18 = perpMarket.getNextFundingFeePerUnit(ctx.fundingRateX18, fillPriceX18);

        // update funding rates
        perpMarket.updateFunding(ctx.fundingRateX18, ctx.fundingFeePerUnitX18);

        // calculate order & settlement fees
        ctx.orderFeeUsdX18 = perpMarket.getOrderFeeUsd(sizeDeltaX18, fillPriceX18);
        ctx.settlementFeeUsdX18 = ud60x18(uint256(settlementConfiguration.fee));

        // fetch storage slot for account's potential existing position in this market
        Position.Data storage oldPosition = Position.load(tradingAccountId, marketId);
        // int256 -> SD59x18
        ctx.oldPositionSizeX18 = sd59x18(oldPosition.size);

        {
            // calculate required initial & maintenance margin for this trade
            // and account's unrealized PNL
            (
                UD60x18 requiredInitialMarginUsdX18,
                UD60x18 requiredMaintenanceMarginUsdX18,
                SD59x18 accountTotalUnrealizedPnlUsdX18
            ) = tradingAccount.getAccountMarginRequirementUsdAndUnrealizedPnlUsd(marketId, sizeDeltaX18);

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
            ctx.shouldUseMaintenanceMargin = !ctx.isIncreasing && !ctx.oldPositionSizeX18.isZero();

            ctx.requiredMarginUsdX18 =
                ctx.shouldUseMaintenanceMargin ? requiredMaintenanceMarginUsdX18 : requiredInitialMarginUsdX18;

            // reverts if the trader can't satisfy the appropriate margin requirement
            tradingAccount.validateMarginRequirement(
                ctx.requiredMarginUsdX18,
                tradingAccount.getMarginBalanceUsd(accountTotalUnrealizedPnlUsdX18),
                ctx.orderFeeUsdX18.add(ctx.settlementFeeUsdX18)
            );
        }

        // cache unrealized PNL from potential existing position in this market
        // including accrued funding
        ctx.pnlUsdX18 =
            oldPosition.getUnrealizedPnl(fillPriceX18).add(oldPosition.getAccruedFunding(ctx.fundingFeePerUnitX18));

        // create new position in working area
        ctx.newPosition = Position.Data({
            size: ctx.oldPositionSizeX18.add(sizeDeltaX18).intoInt256(),
            lastInteractionPrice: fillPriceX18.intoUint128(),
            lastInteractionFundingFeePerUnit: ctx.fundingFeePerUnitX18.intoInt256().toInt128()
        });
        // int256 -> SD59x18
        ctx.newPositionSizeX18 = sd59x18(ctx.newPosition.size);

        // enforce open interest and skew limits for target market and calculate
        // new open interest and new skew
        (ctx.newOpenInterestX18, ctx.newSkewX18) =
            perpMarket.checkOpenInterestLimits(sizeDeltaX18, ctx.oldPositionSizeX18, ctx.newPositionSizeX18);

        // update open interest and skew for this perp market
        perpMarket.updateOpenInterest(ctx.newOpenInterestX18, ctx.newSkewX18);

        // update active markets for this account; may also trigger update
        // to global config set of active accounts
        tradingAccount.updateActiveMarkets(marketId, ctx.oldPositionSizeX18, ctx.newPositionSizeX18);

        // if the position is being closed, clear old position data
        if (ctx.newPositionSizeX18.isZero()) {
            oldPosition.clear();
        }
        // otherwise we are opening a new position or modifying an existing position
        else {
            // revert if new position size is under the minimum for this market
            if (ctx.newPositionSizeX18.abs().lt(sd59x18(int256(uint256(perpMarket.configuration.minTradeSizeX18))))) {
                revert Errors.NewPositionSizeTooSmall();
            }

            // update trader's existing position in this market with new position data
            oldPosition.update(ctx.newPosition);
        }

        // if trader's old position had positive pnl then credit that to the trader
        if (ctx.pnlUsdX18.gt(SD59x18_ZERO)) {
            ctx.marginToAddX18 = ctx.pnlUsdX18.intoUD60x18();
            tradingAccount.deposit(ctx.usdToken, ctx.marginToAddX18);

            // mint settlement tokens credited to trader; tokens are minted to
            // address(this) since they have been credited to trader's deposited collateral
            //
            // NOTE: testnet only - this call will be updated once the Market Making Engine is finalized
            LimitedMintingERC20(ctx.usdToken).mint(address(this), ctx.marginToAddX18.intoUint256());
        }

        // pay order/settlement fees and deduct collateral
        // if trader's old position had negative pnl
        tradingAccount.deductAccountMargin({
            feeRecipients: FeeRecipients.Data({
                marginCollateralRecipient: globalConfiguration.marginCollateralRecipient,
                orderFeeRecipient: globalConfiguration.orderFeeRecipient,
                settlementFeeRecipient: globalConfiguration.settlementFeeRecipient
            }),
            pnlUsdX18: ctx.pnlUsdX18.lt(SD59x18_ZERO) ? ctx.pnlUsdX18.abs().intoUD60x18() : UD60x18_ZERO,
            orderFeeUsdX18: ctx.orderFeeUsdX18,
            settlementFeeUsdX18: ctx.settlementFeeUsdX18
        });

        emit LogFillOrder(
            msg.sender,
            tradingAccountId,
            marketId,
            sizeDeltaX18.intoInt256(),
            fillPriceX18.intoUint256(),
            ctx.orderFeeUsdX18.intoUint256(),
            ctx.settlementFeeUsdX18.intoUint256(),
            ctx.pnlUsdX18.intoInt256(),
            ctx.fundingFeePerUnitX18.intoInt256()
        );
    }

    /// @param sender The sender address.
    /// @param keeper The keeper address.
    function _requireIsKeeper(address sender, address keeper) internal pure {
        if (sender != keeper && keeper != address(0)) {
            revert Errors.OnlyKeeper(sender, keeper);
        }
    }
}
