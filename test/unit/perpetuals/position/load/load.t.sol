// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { Position } from "@zaros/perpetuals/leaves/Position.sol";

contract Position_Load_Unit_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
    }

    function testFuzz_GivenDontHaveAFilledMarketOrder(uint256 marketId) external {
        changePrank({ msgSender: users.naruto.account });

        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        uint128 tradingAccountId = perpsEngine.createTradingAccount(bytes(""), false);

        Position.Data memory position = perpsEngine.exposed_Position_load(tradingAccountId, fuzzMarketConfig.marketId);

        // it should return the size equal to zero
        assertEq(0, position.size, "size should be zero");

        // it should return the lastInteractionPrice equal to zero
        assertEq(0, position.lastInteractionPrice, "lastInteractionPrice should be zero");

        // it should return the lastInteractionFundingFeePerUnit equal to zero
        assertEq(0, position.lastInteractionFundingFeePerUnit, "lastInteractionFundingFeePerUnit should be zero");
    }

    function testFuzz_GivenHaveAFilledMarketOrder(
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

        // it should return the size
        assertEq(size, position.size, "size is not correct");

        // it should return the lastInteractionPrice
        assertEq(
            uint128(fuzzMarketConfig.mockUsdPrice),
            position.lastInteractionPrice,
            "lastInteractionPrice is not correct"
        );

        // it should return the lastInteractionFundingFeePerUnit
        assertEq(
            lastInteractionFundingFeePerUnit,
            position.lastInteractionFundingFeePerUnit,
            "lastInteractionFundingFeePerUnit is not correct"
        );
    }
}
