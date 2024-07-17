// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { IAggregatorV3 } from "@zaros/external/chainlink/interfaces/IAggregatorV3.sol";
import { Constants } from "@zaros/utils/Constants.sol";
import { Errors } from "@zaros/utils/Errors.sol";
import { Math } from "@zaros/utils/Math.sol";
import { ChainlinkUtil } from "@zaros/external/chainlink/ChainlinkUtil.sol";
import { OrderFees } from "@zaros/perpetuals/leaves/OrderFees.sol";
import { MarketConfiguration } from "@zaros/perpetuals/leaves/MarketConfiguration.sol";
import { SettlementConfiguration } from "@zaros/perpetuals/leaves/SettlementConfiguration.sol";
import { GlobalConfiguration } from "@zaros/perpetuals/leaves/GlobalConfiguration.sol";

// Open Zeppelin dependencies
import { SafeCast } from "@openzeppelin/utils/math/SafeCast.sol";

// PRB Math dependencies
import { UD60x18, ud60x18, convert as ud60x18Convert } from "@prb-math/UD60x18.sol";
import {
    SD59x18,
    sd59x18,
    unary,
    UNIT as SD_UNIT,
    ZERO as SD59x18_ZERO,
    convert as sd59x18Convert
} from "@prb-math/SD59x18.sol";

/// @title The PerpMarket namespace.
library PerpMarket {
    using SafeCast for uint256;
    using SafeCast for int256;
    using MarketConfiguration for MarketConfiguration.Data;

    /// @notice ERC7201 storage location.
    bytes32 internal constant PERP_MARKET_LOCATION =
        keccak256(abi.encode(uint256(keccak256("fi.zaros.perpetuals.PerpMarket")) - 1)) & ~bytes32(uint256(0xff));

    /// @notice {PerpMarket} namespace storage structure.
    /// @param id The perp market id.
    /// @param skew The perp market's current skew.
    /// @param openInterest The perp market's current open interest.
    /// @param nextStrategyId The perp market's next settlement strategy id.
    /// @param initialized Whether the perp market is initialized or not.
    /// @param lastFundingRate The perp market's last funding rate value.
    /// @param lastFundingFeePerUnit The perp market's last funding fee per unit value.
    /// @param lastFundingTime The perp market's last funding timestamp.
    /// @param configuration The perp market's configuration data.
    struct Data {
        uint128 id;
        int128 skew;
        uint128 openInterest;
        uint128 nextStrategyId;
        bool initialized;
        int256 lastFundingRate;
        int256 lastFundingFeePerUnit;
        uint256 lastFundingTime;
        MarketConfiguration.Data configuration;
    }

    /// @notice Loads a {PerpMarket}.
    /// @param marketId The perp market id.
    function load(uint128 marketId) internal pure returns (Data storage perpMarket) {
        bytes32 slot = keccak256(abi.encode(PERP_MARKET_LOCATION, marketId));
        assembly {
            perpMarket.slot := slot
        }
    }

    /// @notice Returns the PerpMarket index price based on the price adapter.
    /// @param self The PerpMarket storage pointer.
    function getIndexPrice(Data storage self) internal view returns (UD60x18 indexPrice) {
        address priceAdapter = self.configuration.priceAdapter;
        uint32 priceFeedHeartbeatSeconds = self.configuration.priceFeedHeartbeatSeconds;

        GlobalConfiguration.Data storage globalConfiguration = GlobalConfiguration.load();
        address sequencerUptimeFeed = globalConfiguration.sequencerUptimeFeedByChainId[block.chainid];

        if (priceAdapter == address(0)) {
            revert Errors.PriceAdapterNotDefined(self.id);
        }

        indexPrice = ChainlinkUtil.getPrice(
            IAggregatorV3(priceAdapter), priceFeedHeartbeatSeconds, IAggregatorV3(sequencerUptimeFeed)
        );
    }

    /// @notice Returns the given market's mark price.
    /// @dev The mark price is calculated given the bid/ask or median price of the underlying offchain provider (e.g
    /// CL Data Streams),
    /// and the skew of the market which is used to compute the price impact impact oh the trade.
    /// @dev Liquidity providers of the ZLP Vaults are automatically market making for prices ranging the bid/ask
    /// spread provided by
    /// the offchain oracle with the added spread based on the skew and the configured skew scale.
    /// @param self The PerpMarket storage pointer.
    /// @param skewDelta The skew delta to apply to the mark price calculation.
    /// @param indexPriceX18 The index price of the market.
    function getMarkPrice(
        Data storage self,
        SD59x18 skewDelta,
        UD60x18 indexPriceX18
    )
        internal
        view
        returns (UD60x18 markPrice)
    {
        SD59x18 skewScale = sd59x18(self.configuration.skewScale.toInt256());
        SD59x18 skew = sd59x18(self.skew);

        SD59x18 priceImpactBeforeDelta = skew.div(skewScale);
        SD59x18 newSkew = skew.add(skewDelta);
        SD59x18 priceImpactAfterDelta = newSkew.div(skewScale);

        SD59x18 cachedIndexPriceX18 = indexPriceX18.intoSD59x18();

        UD60x18 priceBeforeDelta =
            cachedIndexPriceX18.add(cachedIndexPriceX18.mul(priceImpactBeforeDelta)).intoUD60x18();
        UD60x18 priceAfterDelta =
            cachedIndexPriceX18.add(cachedIndexPriceX18.mul(priceImpactAfterDelta)).intoUD60x18();

        markPrice = priceBeforeDelta.add(priceAfterDelta).div(ud60x18Convert(2));
    }

    /// @notice Returns the current funding rate of the given market.
    /// @param self The PerpMarket storage pointer.
    function getCurrentFundingRate(Data storage self) internal view returns (SD59x18) {
        return sd59x18(self.lastFundingRate).add(
            getCurrentFundingVelocity(self).mul(getProportionalElapsedSinceLastFunding(self).intoSD59x18())
        );
    }

    /// @notice Returns the current funding velocity of the given market.
    /// @param self The PerpMarket storage pointer.
    function getCurrentFundingVelocity(Data storage self) internal view returns (SD59x18) {
        SD59x18 maxFundingVelocity = sd59x18(uint256(self.configuration.maxFundingVelocity).toInt256());
        SD59x18 skewScale = sd59x18(uint256(self.configuration.skewScale).toInt256());

        SD59x18 skew = sd59x18(self.skew);

        if (skewScale.isZero()) {
            return SD59x18_ZERO;
        }

        SD59x18 proportionalSkew = skew.div(skewScale);
        SD59x18 proportionalSkewBounded = Math.min(Math.max(unary(SD_UNIT), proportionalSkew), SD_UNIT);

        return proportionalSkewBounded.mul(maxFundingVelocity);
    }

    /// @notice Returns the maker or taker order fee in USD.
    /// @dev When the skew is zero, taker fee will be charged.
    /// @param self The PerpMarket storage pointer.
    /// @param sizeDelta The size delta of the order.
    /// @param markPriceX18 The mark price of the market.
    function getOrderFeeUsd(
        Data storage self,
        SD59x18 sizeDelta,
        UD60x18 markPriceX18
    )
        internal
        view
        returns (UD60x18 orderFeeUsd)
    {
        // isSkewGtZero = true,  isBuyOrder = true,  skewIsZero = false -> taker
        // isSkewGtZero = true,  isBuyOrder = false, skewIsZero = false -> maker
        // isSkewGtZero = false, isBuyOrder = true,  skewIsZero = true  -> taker
        // isSkewGtZero = false, isBuyOrder = false, skewIsZero = true  -> taker
        // isSkewGtZero = false, isBuyOrder = true,  skewIsZero = false -> maker

        // get current skew int128 -> SD59x18
        SD59x18 skew = sd59x18(self.skew);

        // is current skew > 0 ?
        bool isSkewGtZero = skew.gt(SD59x18_ZERO);

        // is this order a buy/long ?
        bool isBuyOrder = sizeDelta.gt(SD59x18_ZERO);

        // apply new order's skew to current skew
        SD59x18 newSkew = skew.add(sizeDelta);

        // does the new order result in the skew remaining on the same side?
        // true if:
        //   the new skew  is 0 OR
        //   original skew is 0 OR
        //   new skew > 0 == skew > 0 (new and old skew on the same side)
        bool sameSide =
            newSkew.eq(SD59x18_ZERO) || skew.eq(SD59x18_ZERO) || newSkew.gt(SD59x18_ZERO) == skew.gt(SD59x18_ZERO);

        if (sameSide) {
            // charge (typically) lower maker fee when:
            //    current skew > 0 AND order is sell/short AND current skew != 0
            //    current skew < 0 AND order is buy/long   AND current skew != 0
            UD60x18 feeBps = isSkewGtZero != isBuyOrder && !skew.isZero()
                ? ud60x18(self.configuration.orderFees.makerFee)
                : ud60x18(self.configuration.orderFees.takerFee);

            // output order fee
            orderFeeUsd = markPriceX18.mul(sizeDelta.abs().intoUD60x18()).mul(feeBps);
        }
        // special logic for trades that flip the skew; trader should receive:
        //   makerFee for portion of size that returns skew to 0
        //   takerFee for portion of size that flips skew in other direction
        else {
            // convert new skew abs(SD59x18) -> uint256
            uint256 takerSize = newSkew.abs().intoUint256();

            // abs( abs(orderSize) - abs(newSkew) ) -> uint256
            uint256 makerSize = sizeDelta.abs().sub(sd59x18(int256(takerSize))).abs().intoUint256();

            // calculate corresponding fees for maker and taker portions
            // of this trade which flipped the skew
            UD60x18 takerFee =
                markPriceX18.mul(ud60x18(takerSize)).mul(ud60x18(self.configuration.orderFees.takerFee));
            UD60x18 makerFee =
                markPriceX18.mul(ud60x18(makerSize)).mul(ud60x18(self.configuration.orderFees.makerFee));

            // output order fee
            orderFeeUsd = takerFee.add(makerFee);
        }
    }

    /// @notice Returns the next funding fee per unit value.
    /// @param self The PerpMarket storage pointer.
    /// @param fundingRate The market's current funding rate.
    /// @param markPriceX18 The market's current mark price.
    function getNextFundingFeePerUnit(
        Data storage self,
        SD59x18 fundingRate,
        UD60x18 markPriceX18
    )
        internal
        view
        returns (SD59x18)
    {
        return sd59x18(self.lastFundingFeePerUnit).add(getPendingFundingFeePerUnit(self, fundingRate, markPriceX18));
    }

    /// @notice Returns the pending funding fee per unit value to accumulate.
    /// @param self The PerpMarket storage pointer.
    /// @param fundingRate The market's current funding rate.
    /// @param markPriceX18 The market's current mark price.
    function getPendingFundingFeePerUnit(
        Data storage self,
        SD59x18 fundingRate,
        UD60x18 markPriceX18
    )
        internal
        view
        returns (SD59x18)
    {
        SD59x18 avgFundingRate = unary(sd59x18(self.lastFundingRate).add(fundingRate)).div(sd59x18Convert(2));

        return avgFundingRate.mul(getProportionalElapsedSinceLastFunding(self).intoSD59x18()).mul(
            markPriceX18.intoSD59x18()
        );
    }

    /// @notice Returns the proportional elapsed time since the last funding.
    /// @param self The PerpMarket storage pointer.
    function getProportionalElapsedSinceLastFunding(Data storage self) internal view returns (UD60x18) {
        return ud60x18Convert(block.timestamp - self.lastFundingTime).div(
            ud60x18Convert(Constants.PROPORTIONAL_FUNDING_PERIOD)
        );
    }

    /// @notice Verifies the market's open interest and skew limits based on the next state.
    /// @dev During liquidation we skip the max skew check, so the engine can always liquidate unhealthy accounts.
    /// @dev If the case outlined above happens and the maxSkew is crossed, the market will only allow orders that
    /// reduce the skew.
    /// @param self The PerpMarket storage pointer.
    /// @param sizeDelta The size delta of the order.
    /// @param oldPositionSize The old position size.
    /// @param newPositionSize The new position size.
    function checkOpenInterestLimits(
        Data storage self,
        SD59x18 sizeDelta,
        SD59x18 oldPositionSize,
        SD59x18 newPositionSize
    )
        internal
        view
        returns (UD60x18 newOpenInterest, SD59x18 newSkew)
    {
        // load max & current open interest for this perp market uint128 -> UD60x18
        UD60x18 maxOpenInterest = ud60x18(self.configuration.maxOpenInterest);
        UD60x18 currentOpenInterest = ud60x18(self.openInterest);

        // calculate new open interest which would result from proposed trade
        // by subtracting old position size then adding new position size to
        // current open interest
        newOpenInterest =
            currentOpenInterest.sub(oldPositionSize.abs().intoUD60x18()).add(newPositionSize.abs().intoUD60x18());

        // if new open interest would be greater than this market's max open interest,
        // we still want to allow trades as long as they decrease the open interest. This
        // allows traders to reduce/close their positions in markets where protocol admins
        // have reduced the max open interest to reduce the protocol's exposure to a given
        // perp market
        if (newOpenInterest.gt(maxOpenInterest)) {
            // is the proposed trade reducing open interest?
            bool isReducingOpenInterest = currentOpenInterest.gt(newOpenInterest);

            // revert if the proposed trade isn't reducing open interest
            if (!isReducingOpenInterest) {
                revert Errors.ExceedsOpenInterestLimit(
                    self.id, maxOpenInterest.intoUint256(), newOpenInterest.intoUint256()
                );
            }
        }

        // load max & current skew for this perp market uint128 -> UD60x18 -> SD59x18
        SD59x18 maxSkew = ud60x18(self.configuration.maxSkew).intoSD59x18();
        // int128 -> SD59x18
        SD59x18 currentSkew = sd59x18(self.skew);

        // calculate new skew
        newSkew = currentSkew.add(sizeDelta);

        // similar logic to the open interest check; if the new skew is greater than
        // the max, we still want to allow trades as long as they decrease the skew
        if (newSkew.abs().gt(maxSkew)) {
            bool isReducingSkew = currentSkew.abs().gt(newSkew.abs());

            if (!isReducingSkew) {
                revert Errors.ExceedsSkewLimit(self.id, maxSkew.intoUint256(), newSkew.intoInt256());
            }
        }
    }

    /// @notice Verifies if the trade size is greater than the minimum trade size.
    /// @param self The PerpMarket storage pointer.
    /// @param sizeDeltaX18 The size delta of the order.
    function checkTradeSize(Data storage self, SD59x18 sizeDeltaX18) internal view {
        if (sizeDeltaX18.abs().intoUD60x18().lt(ud60x18(self.configuration.minTradeSizeX18))) {
            revert Errors.TradeSizeTooSmall();
        }
    }

    /// @notice Updates the market's funding values.
    /// @param self The PerpMarket storage pointer.
    /// @param fundingRate The market's current funding rate.
    /// @param fundingFeePerUnit The market's current funding fee per unit.
    function updateFunding(Data storage self, SD59x18 fundingRate, SD59x18 fundingFeePerUnit) internal {
        self.lastFundingRate = fundingRate.intoInt256();
        self.lastFundingFeePerUnit = fundingFeePerUnit.intoInt256();
        self.lastFundingTime = block.timestamp;
    }

    /// @notice Updates the market's open interest and skew values.
    /// @param self The PerpMarket storage pointer.
    /// @param newOpenInterest The new open interest value.
    /// @param newSkew The new skew value.
    function updateOpenInterest(Data storage self, UD60x18 newOpenInterest, SD59x18 newSkew) internal {
        self.skew = newSkew.intoInt256().toInt128();
        self.openInterest = newOpenInterest.intoUint128();
    }

    /// @param marketId The perp market id.
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
    /// @param marketOrderConfiguration The market order settlement configuration of the given perp market.
    /// @param offchainOrdersConfiguration The offchain orders settlement configuration of the given perp market.
    /// @param orderFees The configured maker and taker order fee tiers.
    /// @param priceFeedHeartbeatSeconds The price feed heartbeats in seconds.
    struct CreateParams {
        uint128 marketId;
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
        SettlementConfiguration.Data marketOrderConfiguration;
        SettlementConfiguration.Data offchainOrdersConfiguration;
        OrderFees.Data orderFees;
        uint32 priceFeedHeartbeatSeconds;
    }

    /// @notice Creates a new PerpMarket.
    /// @dev See {CreateParams}.
    function create(CreateParams memory params) internal {
        Data storage self = load(params.marketId);
        if (self.id != 0) {
            revert Errors.MarketAlreadyExists(params.marketId);
        }

        self.id = params.marketId;
        self.initialized = true;

        self.configuration.update(
            MarketConfiguration.Data({
                name: params.name,
                symbol: params.symbol,
                priceAdapter: params.priceAdapter,
                initialMarginRateX18: params.initialMarginRateX18,
                maintenanceMarginRateX18: params.maintenanceMarginRateX18,
                maxOpenInterest: params.maxOpenInterest,
                maxSkew: params.maxSkew,
                maxFundingVelocity: params.maxFundingVelocity,
                minTradeSizeX18: params.minTradeSizeX18,
                skewScale: params.skewScale,
                orderFees: params.orderFees,
                priceFeedHeartbeatSeconds: params.priceFeedHeartbeatSeconds
            })
        );
        SettlementConfiguration.update(
            params.marketId, SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID, params.marketOrderConfiguration
        );

        SettlementConfiguration.update(
            params.marketId,
            SettlementConfiguration.OFFCHAIN_ORDERS_CONFIGURATION_ID,
            params.offchainOrdersConfiguration
        );
    }
}
