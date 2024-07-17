// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { Base_Test } from "test/Base.t.sol";
import { USDToken } from "@zaros/usd/USDToken.sol";

// Open Zeppelin dependencies
import { Ownable } from "@openzeppelin/access/Ownable.sol";

contract USDToken_Mint_Test is Base_Test {
    USDToken token;

    function setUp() public virtual override {
        Base_Test.setUp();

        token = new USDToken(users.owner.account);
    }

    function testFuzz_RevertGiven_TheSenderIsNotTheOwner(uint256 amount) external {
        amount = bound({ x: amount, min: 1, max: 100_000_000e18 });

        changePrank({ msgSender: users.naruto.account });

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.naruto.account)
        });

        token.mint(users.naruto.account, amount);
    }

    modifier givenTheSenderIsTheOwner() {
        _;
    }

    function test_RevertWhen_AmountIsZero() external givenTheSenderIsTheOwner {
        changePrank({ msgSender: users.owner.account });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "amount") });

        token.mint(users.naruto.account, 0);
    }

    function testFuzz_WhenAmountIsNotZero(uint256 amount) external givenTheSenderIsTheOwner {
        amount = bound({ x: amount, min: 1, max: 100_000_000e18 });

        changePrank({ msgSender: users.owner.account });

        token.mint(users.naruto.account, amount);

        // it should mint
        assertEq(amount, token.balanceOf(users.naruto.account), "amount is not correct");
    }
}
