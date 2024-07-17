// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { Errors } from "@zaros/utils/Errors.sol";

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";
import { SD59x18, sd59x18, ZERO as SD59x18_ZERO } from "@prb-math/SD59x18.sol";

contract PerpMarket_CheckOpenInterestLimits_Unit_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    modifier whenTheNewOpenInterestIsGreaterThanTheMaxOpenInterest() {
        _;
    }

    function testFuzz_RevertWhen_IsNotReducingOpenInterest(
        uint256 marketId,
        int256 sizeDelta
    )
        external
        whenTheNewOpenInterestIsGreaterThanTheMaxOpenInterest
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        SD59x18 sizeDeltaX18 = sd59x18(sizeDelta);
        SD59x18 oldPositionSizeX18 = sd59x18(int128(fuzzMarketConfig.maxOi));
        SD59x18 newPositionSizeX18 = oldPositionSizeX18.add(sd59x18(1));

        UD60x18 currentOpenInterest = ud60x18(oldPositionSizeX18.intoUint256());

        perpsEngine.exposed_updateOpenInterest(fuzzMarketConfig.marketId, currentOpenInterest, SD59x18_ZERO);

        UD60x18 expectedNewOpenInterest = currentOpenInterest.sub(oldPositionSizeX18.abs().intoUD60x18()).add(
            newPositionSizeX18.abs().intoUD60x18()
        );

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.ExceedsOpenInterestLimit.selector,
                fuzzMarketConfig.marketId,
                fuzzMarketConfig.maxOi,
                expectedNewOpenInterest.intoUint256()
            )
        });

        perpsEngine.exposed_checkOpenInterestLimits(
            fuzzMarketConfig.marketId, sizeDeltaX18, oldPositionSizeX18, newPositionSizeX18
        );
    }

    function test_WhenIsReducingOpenInterest(uint256 marketId)
        external
        whenTheNewOpenInterestIsGreaterThanTheMaxOpenInterest
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        SD59x18 sizeDeltaX18 = sd59x18(int128(fuzzMarketConfig.maxSkew));
        SD59x18 oldPositionSizeX18 = sd59x18(int128(fuzzMarketConfig.maxOi));
        SD59x18 newPositionSizeX18 = oldPositionSizeX18.sub(sd59x18(1));

        UD60x18 currentOpenInterest = ud60x18(oldPositionSizeX18.intoUint256());

        perpsEngine.exposed_updateOpenInterest(fuzzMarketConfig.marketId, currentOpenInterest, SD59x18_ZERO);

        UD60x18 expectedNewOpenInterest = currentOpenInterest.sub(oldPositionSizeX18.abs().intoUD60x18()).add(
            newPositionSizeX18.abs().intoUD60x18()
        );

        (UD60x18 receivedNewOpenInterest,) = perpsEngine.exposed_checkOpenInterestLimits(
            fuzzMarketConfig.marketId, sizeDeltaX18, oldPositionSizeX18, newPositionSizeX18
        );

        // it should return the new open interest
        assertEq(
            receivedNewOpenInterest.intoUint256(),
            expectedNewOpenInterest.intoUint256(),
            "new open interest is not correct"
        );
    }

    modifier whenTheNewSkewIsGreaterThanTheMaxSkew() {
        _;
    }

    function test_RevertWhen_IsNotReducingSkew(uint256 marketId) external whenTheNewSkewIsGreaterThanTheMaxSkew {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        SD59x18 currentSkew = sd59x18(int128(fuzzMarketConfig.maxSkew));

        SD59x18 sizeDeltaX18 = currentSkew.add(sd59x18(1));
        SD59x18 oldPositionSizeX18 = sd59x18(int128(fuzzMarketConfig.maxOi / 2));
        SD59x18 newPositionSizeX18 = oldPositionSizeX18.add(sd59x18(1));

        UD60x18 currentOpenInterest = ud60x18(oldPositionSizeX18.intoUint256());

        perpsEngine.exposed_updateOpenInterest(fuzzMarketConfig.marketId, currentOpenInterest, currentSkew);

        SD59x18 expectedNewSkew = currentSkew.add(sizeDeltaX18);

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.ExceedsSkewLimit.selector,
                fuzzMarketConfig.marketId,
                fuzzMarketConfig.maxSkew,
                expectedNewSkew.intoInt256()
            )
        });

        perpsEngine.exposed_checkOpenInterestLimits(
            fuzzMarketConfig.marketId, sizeDeltaX18, oldPositionSizeX18, newPositionSizeX18
        );
    }

    function test_WhenIsReducingSkew(uint256 marketId) external whenTheNewSkewIsGreaterThanTheMaxSkew {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        SD59x18 currentSkew = sd59x18(int128(fuzzMarketConfig.maxSkew)).div(sd59x18(2e18));

        SD59x18 sizeDeltaX18 = currentSkew;
        SD59x18 oldPositionSizeX18 = sd59x18(int128(fuzzMarketConfig.maxOi / 2));
        SD59x18 newPositionSizeX18 = oldPositionSizeX18.add(sd59x18(1));

        UD60x18 currentOpenInterest = ud60x18(oldPositionSizeX18.intoUint256());

        perpsEngine.exposed_updateOpenInterest(fuzzMarketConfig.marketId, currentOpenInterest, currentSkew);

        SD59x18 expectedNewSkew = currentSkew.add(sizeDeltaX18);

        (, SD59x18 receivedNewSkew) = perpsEngine.exposed_checkOpenInterestLimits(
            fuzzMarketConfig.marketId, sizeDeltaX18, oldPositionSizeX18, newPositionSizeX18
        );

        // it should return the new skew
        assertEq(receivedNewSkew.intoInt256(), expectedNewSkew.intoInt256(), "new skew is not correct");
    }
}
