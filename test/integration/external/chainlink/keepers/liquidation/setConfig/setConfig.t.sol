// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { Base_Test } from "test/Base.t.sol";
import { LiquidationKeeper } from "@zaros/external/chainlink/keepers/liquidation/LiquidationKeeper.sol";
import { ChainlinkAutomationUtils } from "script/utils/ChainlinkAutomationUtils.sol";

// Open Zeppelin dependencies
import { Ownable } from "@openzeppelin/access/Ownable.sol";

contract LiquidationKeeper_SetConfig_Integration_Test is Base_Test {
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

    modifier givenCallSetConfigFunction() {
        _;
    }

    function test_RevertWhen_IAmNotTheOwner() external givenInitializeContract givenCallSetConfigFunction {
        changePrank({ msgSender: users.naruto.account });

        address liquidationKeeper =
            ChainlinkAutomationUtils.deployLiquidationKeeper(users.owner.account, address(perpsEngine));

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.naruto.account)
        });

        LiquidationKeeper(liquidationKeeper).setConfig(address(perpsEngine));
    }

    modifier whenIAmTheOwner() {
        _;
    }

    function test_WhenIAmTheOwner() external givenInitializeContract givenCallSetConfigFunction whenIAmTheOwner {
        changePrank({ msgSender: users.owner.account });

        address liquidationKeeper =
            ChainlinkAutomationUtils.deployLiquidationKeeper(users.owner.account, address(perpsEngine));

        LiquidationKeeper(liquidationKeeper).setConfig(address(perpsEngine));

        // it should update config
        (address keeperOwner, address perpsEngineOfLiquidationKeeper) =
            LiquidationKeeper(liquidationKeeper).getConfig();

        assertEq(keeperOwner, users.owner.account, "owner is not correct");

        assertEq(perpsEngineOfLiquidationKeeper, address(perpsEngine), "owner is not correct");
    }

    function test_RevertWhen_PerpsEngineIsZero()
        external
        givenInitializeContract
        givenCallSetConfigFunction
        whenIAmTheOwner
    {
        changePrank({ msgSender: users.owner.account });

        address liquidationKeeper =
            ChainlinkAutomationUtils.deployLiquidationKeeper(users.owner.account, address(perpsEngine));

        address perpsEngine = address(0);

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "perpsEngine") });

        LiquidationKeeper(liquidationKeeper).setConfig(perpsEngine);
    }
}
