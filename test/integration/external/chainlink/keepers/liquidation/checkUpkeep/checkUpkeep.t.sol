// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { LiquidationKeeper } from "@zaros/external/chainlink/keepers/liquidation/LiquidationKeeper.sol";
import { Base_Test } from "test/Base.t.sol";

contract LiquidationKeeper_CheckUpkeep_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function testFuzz_RevertWhen_TheCheckLowerBoundIsEqualThenTheCheckUpperBound(
        uint256 checkLowerBound,
        uint256 checkUpperBound,
        uint256 performLowerBound,
        uint256 performUpperBound
    )
        external
    {
        checkLowerBound = bound({ x: checkLowerBound, min: 1, max: 1000 });
        checkUpperBound = checkLowerBound;
        performLowerBound = bound({ x: performLowerBound, min: 0, max: 1000 });
        performUpperBound = bound({ x: performUpperBound, min: performLowerBound + 1, max: performLowerBound + 16 });

        bytes memory checkData = abi.encode(checkLowerBound, checkUpperBound, performLowerBound, performUpperBound);

        // it should revert
        vm.expectRevert({ revertData: Errors.InvalidBounds.selector });
        LiquidationKeeper(liquidationKeeper).checkUpkeep(checkData);
    }

    function testFuzz_RevertWhen_TheCheckLowerBoundIsHigherThanTheCheckUpperBound(
        uint256 checkLowerBound,
        uint256 checkUpperBound,
        uint256 performLowerBound,
        uint256 performUpperBound
    )
        external
    {
        checkLowerBound = bound({ x: checkLowerBound, min: 1, max: 1000 });
        checkUpperBound = bound({ x: checkUpperBound, min: 0, max: checkLowerBound - 1 });
        performLowerBound = bound({ x: performLowerBound, min: 0, max: 1000 });
        performUpperBound = bound({ x: performUpperBound, min: performLowerBound + 1, max: performLowerBound + 16 });

        bytes memory checkData = abi.encode(checkLowerBound, checkUpperBound, performLowerBound, performUpperBound);

        // it should revert
        vm.expectRevert({ revertData: Errors.InvalidBounds.selector });
        LiquidationKeeper(liquidationKeeper).checkUpkeep(checkData);
    }

    modifier whenTheCheckLowerBoundIsLowerThanTheCheckUpperBound() {
        _;
    }

    function testFuzz_RevertWhen_ThePerformLowerBoundIsEqualToThePerformUpperBound(
        uint256 checkLowerBound,
        uint256 checkUpperBound,
        uint256 performLowerBound,
        uint256 performUpperBound
    )
        external
        whenTheCheckLowerBoundIsLowerThanTheCheckUpperBound
    {
        checkLowerBound = bound({ x: checkLowerBound, min: 0, max: 1000 });
        checkUpperBound = bound({ x: checkUpperBound, min: checkLowerBound + 1, max: checkLowerBound + 101 });
        performLowerBound = bound({ x: performLowerBound, min: 1, max: 1000 });
        performUpperBound = performLowerBound;

        bytes memory checkData = abi.encode(checkLowerBound, checkUpperBound, performLowerBound, performUpperBound);

        // it should revert
        vm.expectRevert({ revertData: Errors.InvalidBounds.selector });
        LiquidationKeeper(liquidationKeeper).checkUpkeep(checkData);
    }

    function testFuzz_RevertWhen_ThePerformLowerBoundIsHigherThanThePerformUpperBound(
        uint256 checkLowerBound,
        uint256 checkUpperBound,
        uint256 performLowerBound,
        uint256 performUpperBound
    )
        external
        whenTheCheckLowerBoundIsLowerThanTheCheckUpperBound
    {
        checkLowerBound = bound({ x: checkLowerBound, min: 0, max: 1000 });
        checkUpperBound = bound({ x: checkUpperBound, min: checkLowerBound + 1, max: checkLowerBound + 101 });
        performLowerBound = bound({ x: performLowerBound, min: 1, max: 1000 });
        performUpperBound = bound({ x: performUpperBound, min: 0, max: performLowerBound - 1 });

        bytes memory checkData = abi.encode(checkLowerBound, checkUpperBound, performLowerBound, performUpperBound);

        // it should revert
        vm.expectRevert({ revertData: Errors.InvalidBounds.selector });
        LiquidationKeeper(liquidationKeeper).checkUpkeep(checkData);
    }

    modifier whenThePerformLowerBoundIsLowerThanThePerformUpperBound() {
        _;
    }

    function testFuzz_GivenThereAreNoLiquidatableAccountsIds(
        uint256 checkLowerBound,
        uint256 checkUpperBound,
        uint256 performLowerBound,
        uint256 performUpperBound
    )
        external
        whenTheCheckLowerBoundIsLowerThanTheCheckUpperBound
        whenThePerformLowerBoundIsLowerThanThePerformUpperBound
    {
        checkLowerBound = bound({ x: checkLowerBound, min: 0, max: 1000 });
        checkUpperBound = bound({ x: checkUpperBound, min: checkLowerBound + 1, max: checkLowerBound + 101 });
        performLowerBound = bound({ x: performLowerBound, min: 0, max: 1000 });
        performUpperBound = bound({ x: performUpperBound, min: performLowerBound + 1, max: performLowerBound + 16 });

        bytes memory checkData = abi.encode(checkLowerBound, checkUpperBound, performLowerBound, performUpperBound);

        (bool upkeepNeeded, bytes memory performData) = LiquidationKeeper(liquidationKeeper).checkUpkeep(checkData);

        // it should return upkeepNeeded == false
        assertFalse(upkeepNeeded, "upkeepNeeded");
        uint128[] memory liquidatableAccountsIds = abi.decode(performData, (uint128[]));

        for (uint256 i; i < liquidatableAccountsIds.length; i++) {
            assertEq(liquidatableAccountsIds[i], 0, "liquidatableAccountsIds");
        }
    }

    struct TestFuzz_GivenThereAreLiquidatableAccounts_Context {
        uint256 checkLowerBound;
        uint256 checkUpperBound;
        uint256 performLowerBound;
        uint256 performUpperBound;
        bytes checkData;
        MarketConfig fuzzMarketConfig;
        uint256 amountOfTradingAccounts;
        uint256 marginValueUsd;
        uint256 initialMarginRate;
        uint256 accountMarginValueUsd;
        uint128 tradingAccountId;
        bool upkeepNeeded;
        bytes performData;
        uint128[] liquidatableAccountsIds;
    }

    function testFuzz_GivenThereAreLiquidatableAccounts(
        uint256 marketId,
        bool isLong
    )
        external
        whenTheCheckLowerBoundIsLowerThanTheCheckUpperBound
        whenThePerformLowerBoundIsLowerThanThePerformUpperBound
    {
        TestFuzz_GivenThereAreLiquidatableAccounts_Context memory ctx;
        ctx.checkLowerBound = 0;
        ctx.checkUpperBound = 49;
        ctx.performLowerBound = 2;
        ctx.performUpperBound = 11;

        ctx.fuzzMarketConfig = getFuzzMarketConfig(marketId);
        ctx.amountOfTradingAccounts = 12;
        ctx.marginValueUsd = 100_000e18 / ctx.amountOfTradingAccounts;
        ctx.initialMarginRate = ctx.fuzzMarketConfig.imr;

        ctx.checkData =
            abi.encode(ctx.checkLowerBound, ctx.checkUpperBound, ctx.performLowerBound, ctx.performUpperBound);

        deal({ token: address(usdz), to: users.naruto.account, give: ctx.marginValueUsd });

        for (uint256 i; i < ctx.amountOfTradingAccounts; i++) {
            ctx.accountMarginValueUsd = ctx.marginValueUsd / ctx.amountOfTradingAccounts;
            ctx.tradingAccountId = createAccountAndDeposit(ctx.accountMarginValueUsd, address(usdz));

            openPosition(
                ctx.fuzzMarketConfig, ctx.tradingAccountId, ctx.initialMarginRate, ctx.accountMarginValueUsd, isLong
            );
        }
        setAccountsAsLiquidatable(ctx.fuzzMarketConfig, isLong);

        (ctx.upkeepNeeded, ctx.performData) = LiquidationKeeper(liquidationKeeper).checkUpkeep(ctx.checkData);

        // it should return upkeepNeeded == true
        assertTrue(ctx.upkeepNeeded, "upkeepNeeded ");
        // it should return the abi encoded liquidatable accounts ids
        ctx.liquidatableAccountsIds = abi.decode(ctx.performData, (uint128[]));

        for (uint256 i; i < ctx.liquidatableAccountsIds.length; i++) {
            assertEq(ctx.liquidatableAccountsIds[i], ctx.performLowerBound + i + 1, "liquidatableAccountsIds");
        }
    }
}
