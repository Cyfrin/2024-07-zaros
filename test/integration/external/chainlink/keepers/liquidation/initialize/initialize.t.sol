// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { Base_Test } from "test/Base.t.sol";
import { LiquidationKeeper } from "@zaros/external/chainlink/keepers/liquidation/LiquidationKeeper.sol";

// Open Zeppelin dependencies
import { ERC1967Proxy } from "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

contract LiquidationKeeper_Initialize_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();

        createPerpMarkets();

        changePrank({ msgSender: users.naruto.account });
    }

    modifier givenInitializeContractWithSomeWrongInformation() {
        _;
    }

    function test_RevertWhen_AddressOfPerpsEngineIsZero() external givenInitializeContractWithSomeWrongInformation {
        address liquidationKeeperImplementation = address(new LiquidationKeeper());

        address perpsEngine = address(0);

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "perpsEngine") });

        new ERC1967Proxy(
            liquidationKeeperImplementation,
            abi.encodeWithSelector(
                LiquidationKeeper.initialize.selector,
                users.owner.account,
                perpsEngine,
                users.settlementFeeRecipient.account
            )
        );
    }
}
