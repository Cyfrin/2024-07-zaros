// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { Base_Test } from "test/Base.t.sol";

contract CheckMarketIsEnabled_Unit_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function testFuzz_RevertWhen_TheMarketIsNotEnabled(uint256 marketId) external {
        marketId = bound({ x: marketId, min: FINAL_MARKET_ID + 1, max: 1_000_000e18 });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.PerpMarketDisabled.selector, uint128(marketId)) });

        perpsEngine.exposed_checkMarketIsEnabled(uint128(marketId));
    }

    function testFuzz_WhenTheMarketIsEnabled(uint256 marketId) external view {
        marketId = bound({ x: marketId, min: INITIAL_MARKET_ID, max: FINAL_MARKET_ID });

        // it should return nothing
        perpsEngine.exposed_checkMarketIsEnabled(uint128(marketId));
    }
}
