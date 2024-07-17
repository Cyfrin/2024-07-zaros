// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { LiquidationKeeper } from "@zaros/external/chainlink/keepers/liquidation/LiquidationKeeper.sol";
import { ChainlinkAutomationUtils } from "script/utils/ChainlinkAutomationUtils.sol";

contract LiquidationKeeper_GetConfig_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();

        createPerpMarkets();

        changePrank({ msgSender: users.naruto.account });
    }

    modifier givenInitializeContract() {
        _;
    }

    function test_WhenCallGetConfigFunction() external givenInitializeContract {
        address liquidationKeeper =
            ChainlinkAutomationUtils.deployLiquidationKeeper(users.owner.account, address(perpsEngine));

        (address keeperOwner, address perpsEngineOfLiquidationKeeper) =
            LiquidationKeeper(liquidationKeeper).getConfig();

        // it should return owner
        assertEq(keeperOwner, users.owner.account, "owner is not correct");

        // it should return perpsEngine
        assertEq(perpsEngineOfLiquidationKeeper, address(perpsEngine), "owner is not correct");
    }
}
