// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Constants } from "@zaros/utils/Constants.sol";
import { Math } from "@zaros/utils/Math.sol";
import { PerpMarket } from "@zaros/perpetuals/leaves/PerpMarket.sol";
import { Base_Test } from "test/Base.t.sol";
import { PerpMarketHarness } from "test/harnesses/perpetuals/leaves/PerpMarketHarness.sol";

// PRB Math dependencies
import { UD60x18, ud60x18, convert as ud60x18Convert } from "@prb-math/UD60x18.sol";
import { SD59x18, sd59x18, ZERO as SD59x18_ZERO } from "@prb-math/SD59x18.sol";

// Open Zeppelin dependencies
import { SafeCast } from "@openzeppelin/utils/math/SafeCast.sol";

contract GetMarkPrice_Integration_Test is Base_Test {
    using SafeCast for uint256;

    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function testFuzz_GivenTheresAMarketCreated(
        uint128 marketId,
        uint256 marginValueUsd,
        bool isLong,
        uint256 timeElapsed
    )
        external
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);
        marginValueUsd = bound({
            x: marginValueUsd,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });
        timeElapsed = bound({ x: timeElapsed, min: 1 seconds, max: 365 days });

        deal({ token: address(usdc), to: users.naruto.account, give: marginValueUsd });

        uint128 tradingAccountId = createAccountAndDeposit(marginValueUsd, address(usdc));

        openPosition(
            fuzzMarketConfig,
            tradingAccountId,
            ud60x18(fuzzMarketConfig.imr).mul(ud60x18(1.001e18)).intoUint256(),
            marginValueUsd,
            isLong
        );

        skip(timeElapsed);

        UD60x18 indexPriceX18 = ud60x18(fuzzMarketConfig.mockUsdPrice);

        PerpMarket.Data memory perpMarket =
            PerpMarketHarness(address(perpsEngine)).exposed_PerpMarket_load(fuzzMarketConfig.marketId);

        SD59x18 skewScale = sd59x18(uint256(perpMarket.configuration.skewScale).toInt256());

        SD59x18 priceImpactBeforeDelta = sd59x18(perpMarket.skew).div(skewScale);
        SD59x18 newSkew = sd59x18(perpMarket.skew).add(SD59x18_ZERO);
        SD59x18 priceImpactAfterDelta = newSkew.div(skewScale);

        UD60x18 priceBeforeDelta =
            indexPriceX18.intoSD59x18().add(indexPriceX18.intoSD59x18().mul(priceImpactBeforeDelta)).intoUD60x18();
        UD60x18 priceAfterDelta =
            indexPriceX18.intoSD59x18().add(indexPriceX18.intoSD59x18().mul(priceImpactAfterDelta)).intoUD60x18();

        uint256 expectedMarkPrice = priceBeforeDelta.add(priceAfterDelta).div(ud60x18Convert(2)).intoUint256();
        UD60x18 markPrice = perpsEngine.getMarkPrice(fuzzMarketConfig.marketId, indexPriceX18.intoUint256(), 0);

        // it should return the funding velocity
        assertEq(markPrice.intoUint256(), expectedMarkPrice, "invalid mark price");
    }
}
