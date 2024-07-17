// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Constants } from "@zaros/utils/Constants.sol";
import { Math } from "@zaros/utils/Math.sol";
import { PerpMarket } from "@zaros/perpetuals/leaves/PerpMarket.sol";
import { Base_Test } from "test/Base.t.sol";
import { PerpMarketHarness } from "test/harnesses/perpetuals/leaves/PerpMarketHarness.sol";

// PRB Math dependencies
import { ud60x18 } from "@prb-math/UD60x18.sol";
import { SD59x18, sd59x18, UNIT as SD_UNIT, unary } from "@prb-math/SD59x18.sol";

// Open Zeppelin dependencies
import { SafeCast } from "@openzeppelin/utils/math/SafeCast.sol";

contract GetFundingVelocity_Integration_Test is Base_Test {
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

        uint256 initialMarginRate = ud60x18(fuzzMarketConfig.imr).mul(ud60x18(1.001e18)).intoUint256();
        uint128 tradingAccountId = createAccountAndDeposit(marginValueUsd, address(usdc));

        openPosition(fuzzMarketConfig, tradingAccountId, initialMarginRate, marginValueUsd, isLong);

        skip(timeElapsed);

        PerpMarket.Data memory perpMarket =
            PerpMarketHarness(address(perpsEngine)).exposed_PerpMarket_load(fuzzMarketConfig.marketId);
        SD59x18 maxFundingVelocity = sd59x18(uint256(perpMarket.configuration.maxFundingVelocity).toInt256());
        SD59x18 skewScale = sd59x18(uint256(perpMarket.configuration.skewScale).toInt256());

        SD59x18 skew = sd59x18(perpMarket.skew);

        SD59x18 proportionalSkew = skew.div(skewScale);
        SD59x18 proportionalSkewBounded = Math.min(Math.max(unary(SD_UNIT), proportionalSkew), SD_UNIT);

        int256 expectedFundingVelocity = proportionalSkewBounded.mul(maxFundingVelocity).intoInt256();
        SD59x18 fundingVelocity = perpsEngine.getFundingVelocity(fuzzMarketConfig.marketId);

        // it should return the funding velocity
        assertEq(fundingVelocity.intoInt256(), expectedFundingVelocity, "invalid funding velocity");
    }
}
