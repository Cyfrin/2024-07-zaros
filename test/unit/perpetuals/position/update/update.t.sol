// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { Position } from "@zaros/perpetuals/leaves/Position.sol";

// Open Zeppelin dependencies
import { SafeCast } from "@openzeppelin/utils/math/SafeCast.sol";

contract Position_Update_Unit_Test is Base_Test {
    using SafeCast for int256;

    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
    }

    function testFuzz_WhenUpdateIsCalled(
        uint256 marketId,
        uint256 sizeAbs,
        bool isLong,
        int128 lastInteractionFundingFeePerUnit
    )
        external
    {
        changePrank({ msgSender: users.naruto.account });

        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        sizeAbs =
            bound({ x: sizeAbs, min: uint256(fuzzMarketConfig.minTradeSize), max: uint256(fuzzMarketConfig.maxSkew) });
        int256 size = isLong ? int256(sizeAbs) : -int256(sizeAbs);

        uint128 tradingAccountId = perpsEngine.createTradingAccount(bytes(""), false);

        Position.Data memory mockPosition = Position.Data({
            size: size,
            lastInteractionPrice: uint128(fuzzMarketConfig.mockUsdPrice),
            lastInteractionFundingFeePerUnit: lastInteractionFundingFeePerUnit
        });

        perpsEngine.exposed_update(tradingAccountId, fuzzMarketConfig.marketId, mockPosition);

        Position.Data memory position = perpsEngine.exposed_Position_load(tradingAccountId, fuzzMarketConfig.marketId);

        // it should update the size
        assertEq(position.size, mockPosition.size, "Position size not updated");

        // it should update the lastInteractionPrice
        assertEq(
            position.lastInteractionPrice,
            mockPosition.lastInteractionPrice,
            "Position lastInteractionPrice not updated"
        );

        // it should update the lastInteractionFundingFeePerUnit
        assertEq(
            position.lastInteractionFundingFeePerUnit,
            mockPosition.lastInteractionFundingFeePerUnit,
            "Position lastInteractionFundingFeePerUnit not updated"
        );
    }
}
