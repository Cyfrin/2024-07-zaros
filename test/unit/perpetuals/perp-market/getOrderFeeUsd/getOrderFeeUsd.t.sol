// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";
import { SD59x18, sd59x18, unary } from "@prb-math/SD59x18.sol";

// Open Zeppelin dependencies
import { SafeCast } from "@openzeppelin/utils/math/SafeCast.sol";

contract PerpMarket_GetOrderFeeUsd_Unit_Test is Base_Test {
    using SafeCast for int256;

    UD60x18 internal mockOpenInterest = ud60x18(1e6);

    function setUp() public virtual override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    modifier whenSizeDeltaDoesntFlipTheSkew() {
        _;
    }

    function testFuzz_WhenSkewIsZero(
        uint256 marketId,
        uint256 sizeDeltaAbs
    )
        external
        whenSizeDeltaDoesntFlipTheSkew
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        sizeDeltaAbs = bound({ x: sizeDeltaAbs, min: 1, max: fuzzMarketConfig.maxSkew });

        int128 skew = 0;

        perpsEngine.exposed_updateOpenInterest(fuzzMarketConfig.marketId, mockOpenInterest, sd59x18(skew));

        SD59x18 sizeDeltaX18 = sd59x18(int256(sizeDeltaAbs));

        UD60x18 markPriceX18 = ud60x18(fuzzMarketConfig.mockUsdPrice);

        UD60x18 feeUsd = perpsEngine.exposed_getOrderFeeUsd(fuzzMarketConfig.marketId, sizeDeltaX18, markPriceX18);

        UD60x18 expectedFeeUsd =
            markPriceX18.mul(sizeDeltaX18.abs().intoUD60x18()).mul(ud60x18(fuzzMarketConfig.orderFees.takerFee));

        // it should return the taker order fee
        assertEq(expectedFeeUsd.intoUint256(), feeUsd.intoUint256(), "should return the taker order fee");
    }

    function testFuzz_WhenSkewAndSizeDeltaAreGreaterThanZero(
        uint256 marketId,
        uint256 skewAbs,
        uint256 sizeDeltaAbs
    )
        external
        whenSizeDeltaDoesntFlipTheSkew
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        sizeDeltaAbs = bound({ x: sizeDeltaAbs, min: 1, max: fuzzMarketConfig.maxSkew });

        skewAbs = bound({ x: skewAbs, min: 1, max: fuzzMarketConfig.maxSkew });
        int128 skew = int128(int256(skewAbs));

        perpsEngine.exposed_updateOpenInterest(fuzzMarketConfig.marketId, mockOpenInterest, sd59x18(skew));

        SD59x18 sizeDeltaX18 = sd59x18(int256(sizeDeltaAbs));

        UD60x18 markPriceX18 = ud60x18(fuzzMarketConfig.mockUsdPrice);

        UD60x18 feeUsd = perpsEngine.exposed_getOrderFeeUsd(fuzzMarketConfig.marketId, sizeDeltaX18, markPriceX18);

        UD60x18 expectedFeeUsd =
            markPriceX18.mul(sizeDeltaX18.abs().intoUD60x18()).mul(ud60x18(fuzzMarketConfig.orderFees.takerFee));

        // it should return the taker order fee
        assertEq(expectedFeeUsd.intoUint256(), feeUsd.intoUint256(), "should return the taker order fee");
    }

    function test_WhenSkewAndSizeDeltaAreLessThanZero(
        uint256 marketId,
        uint256 skewAbs,
        uint256 sizeDeltaAbs
    )
        external
        whenSizeDeltaDoesntFlipTheSkew
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        sizeDeltaAbs = bound({ x: sizeDeltaAbs, min: 1, max: fuzzMarketConfig.maxSkew });

        skewAbs = bound({ x: skewAbs, min: 1, max: fuzzMarketConfig.maxSkew });
        int128 skew = int128(int256(skewAbs));

        perpsEngine.exposed_updateOpenInterest(fuzzMarketConfig.marketId, mockOpenInterest, unary(sd59x18(skew)));

        SD59x18 sizeDeltaX18 = unary(sd59x18(int256(sizeDeltaAbs)));

        UD60x18 markPriceX18 = ud60x18(fuzzMarketConfig.mockUsdPrice);

        UD60x18 feeUsd = perpsEngine.exposed_getOrderFeeUsd(fuzzMarketConfig.marketId, sizeDeltaX18, markPriceX18);

        UD60x18 expectedFeeUsd =
            markPriceX18.mul(sizeDeltaX18.abs().intoUD60x18()).mul(ud60x18(fuzzMarketConfig.orderFees.takerFee));

        // it should return the taker order fee
        assertEq(expectedFeeUsd.intoUint256(), feeUsd.intoUint256(), "should return the taker order fee");
    }

    function test_WhenSkewIsGreaterThanZeroAndSizeDeltaIsLessThanZero(
        uint256 marketId,
        uint256 skewAbs,
        uint256 sizeDeltaAbs
    )
        external
        whenSizeDeltaDoesntFlipTheSkew
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        sizeDeltaAbs = bound({ x: sizeDeltaAbs, min: 1, max: fuzzMarketConfig.maxSkew });

        skewAbs = bound({ x: skewAbs, min: 1, max: fuzzMarketConfig.maxSkew });

        vm.assume(skewAbs > sizeDeltaAbs);

        int128 skew = int128(int256(skewAbs));

        perpsEngine.exposed_updateOpenInterest(fuzzMarketConfig.marketId, mockOpenInterest, sd59x18(skew));

        SD59x18 sizeDeltaX18 = unary(sd59x18(int256(sizeDeltaAbs)));

        UD60x18 markPriceX18 = ud60x18(fuzzMarketConfig.mockUsdPrice);

        UD60x18 feeUsd = perpsEngine.exposed_getOrderFeeUsd(fuzzMarketConfig.marketId, sizeDeltaX18, markPriceX18);

        UD60x18 expectedFeeUsd =
            markPriceX18.mul(sizeDeltaX18.abs().intoUD60x18()).mul(ud60x18(fuzzMarketConfig.orderFees.makerFee));

        // it should return the maker order fee
        assertEq(expectedFeeUsd.intoUint256(), feeUsd.intoUint256(), "should return the maker order fee");
    }

    function test_WhenSkewIsLessThanZeroAndSizeDeltaIsGreaterThanZero(
        uint256 marketId,
        uint256 skewAbs,
        uint256 sizeDeltaAbs
    )
        external
        whenSizeDeltaDoesntFlipTheSkew
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        sizeDeltaAbs = bound({ x: sizeDeltaAbs, min: 1, max: fuzzMarketConfig.maxSkew });

        skewAbs = bound({ x: skewAbs, min: 1, max: fuzzMarketConfig.maxSkew });

        vm.assume(skewAbs > sizeDeltaAbs);

        int128 skew = int128(int256(skewAbs));

        perpsEngine.exposed_updateOpenInterest(fuzzMarketConfig.marketId, mockOpenInterest, unary(sd59x18(skew)));

        SD59x18 sizeDeltaX18 = sd59x18(int256(sizeDeltaAbs));

        UD60x18 markPriceX18 = ud60x18(fuzzMarketConfig.mockUsdPrice);

        UD60x18 feeUsd = perpsEngine.exposed_getOrderFeeUsd(fuzzMarketConfig.marketId, sizeDeltaX18, markPriceX18);

        UD60x18 expectedFeeUsd =
            markPriceX18.mul(sizeDeltaX18.abs().intoUD60x18()).mul(ud60x18(fuzzMarketConfig.orderFees.makerFee));

        // it should return the maker order fee
        assertEq(expectedFeeUsd.intoUint256(), feeUsd.intoUint256(), "should return the maker order fee");
    }

    function test_WhenSizeDeltaFlipsTheSkew(uint256 marketId, uint256 skewAbs, uint256 sizeDeltaAbs) external {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        sizeDeltaAbs = bound({ x: sizeDeltaAbs, min: 1, max: fuzzMarketConfig.maxSkew });

        skewAbs = bound({ x: skewAbs, min: 1, max: fuzzMarketConfig.maxSkew });

        vm.assume(sizeDeltaAbs > skewAbs);

        int128 skew = -int128(int256(skewAbs));

        perpsEngine.exposed_updateOpenInterest(fuzzMarketConfig.marketId, mockOpenInterest, (sd59x18(skew)));

        SD59x18 sizeDeltaX18 = sd59x18(int256(sizeDeltaAbs));

        UD60x18 markPriceX18 = ud60x18(fuzzMarketConfig.mockUsdPrice);

        UD60x18 feeUsd = perpsEngine.exposed_getOrderFeeUsd(fuzzMarketConfig.marketId, sizeDeltaX18, markPriceX18);

        uint256 takerSize = sd59x18(skew).add(sizeDeltaX18).abs().intoUint256();
        uint256 makerSize = sizeDeltaX18.abs().sub(sd59x18(int256(takerSize))).abs().intoUint256();

        UD60x18 takerFee = markPriceX18.mul(ud60x18(takerSize)).mul(ud60x18(fuzzMarketConfig.orderFees.takerFee));
        UD60x18 makerFee = markPriceX18.mul(ud60x18(makerSize)).mul(ud60x18(fuzzMarketConfig.orderFees.makerFee));

        UD60x18 expectedFeeUsd = takerFee.add(makerFee);

        // it should return the taker fee sum with maker fee
        assertEq(expectedFeeUsd.intoUint256(), feeUsd.intoUint256(), "should return the maker order fee");
    }
}
