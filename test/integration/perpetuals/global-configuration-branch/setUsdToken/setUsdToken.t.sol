// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { Base_Test } from "test/Base.t.sol";
import { GlobalConfigurationBranch } from "@zaros/perpetuals/branches/GlobalConfigurationBranch.sol";

// Open Zeppelin dependencies
import { Ownable } from "@openzeppelin/access/Ownable.sol";

contract SetUsdToken_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
    }

    function testFuzz_RevertGiven_TheSenderIsNotTheOwner(address newUsdToken) external {
        changePrank({ msgSender: users.naruto.account });

        vm.assume(newUsdToken != address(0));

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.naruto.account)
        });

        perpsEngine.setUsdToken(newUsdToken);
    }

    modifier givenTheSenderIsTheOwner() {
        _;
    }

    function test_RevertWhen_TheUsdTokenIsZero() external givenTheSenderIsTheOwner {
        changePrank({ msgSender: users.owner.account });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "usdToken") });

        perpsEngine.setUsdToken(address(0));
    }

    function test_WhenTheUsdTokenIsNotAZero(address newUsdToken) external givenTheSenderIsTheOwner {
        changePrank({ msgSender: users.owner.account });

        vm.assume(newUsdToken != address(0));

        // it should emit a {LogSetUsdToken} event
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit GlobalConfigurationBranch.LogSetUsdToken(users.owner.account, newUsdToken);

        perpsEngine.setUsdToken(newUsdToken);

        address receivedUsdToken = perpsEngine.workaround_getUsdToken();

        // it should update on storage
        assertEq(newUsdToken, receivedUsdToken, "trading account token should be updated on storage");
    }
}
