// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { Base_Test } from "test/Base.t.sol";

contract RemoveMarket_Unit_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function testFuzz_RevertWhen_TheMarketIsAlreadyRemoved(uint256 marketId) external {
        uint256 marketNotAdded = FINAL_MARKET_ID + 1;
        marketId = bound({ x: marketId, min: INITIAL_MARKET_ID, max: FINAL_MARKET_ID });

        perpsEngine.exposed_removeMarket(uint128(marketId));

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.PerpMarketAlreadyDisabled.selector, uint128(marketId))
        });

        perpsEngine.exposed_removeMarket(uint128(marketId));

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.PerpMarketAlreadyDisabled.selector, uint128(marketNotAdded))
        });

        perpsEngine.exposed_removeMarket(uint128(marketNotAdded));
    }

    function testFuzz_WhenTheMarketWasNotRemoved(uint256 marketId) external {
        marketId = bound({ x: marketId, min: INITIAL_MARKET_ID, max: FINAL_MARKET_ID });

        // it should remove the market
        perpsEngine.exposed_removeMarket(uint128(marketId));

        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.PerpMarketDisabled.selector, uint128(marketId)) });

        perpsEngine.exposed_checkMarketIsEnabled(uint128(marketId));
    }
}
