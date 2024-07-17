// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { Base_Test } from "test/Base.t.sol";
import { TradingAccount } from "@zaros/perpetuals/leaves/TradingAccount.sol";

contract NotifyAccountTransfer_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
    }

    function test_RevertGiven_TheSenderIsNotTheAccountNftContract() external {
        changePrank({ msgSender: users.naruto.account });

        uint128 tradingAccountId = perpsEngine.createTradingAccount(bytes(""), false);

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.OnlyTradingAccountToken.selector, users.naruto.account)
        });

        perpsEngine.notifyAccountTransfer(users.madara.account, tradingAccountId);
    }

    function testFuzz_GivenTheSenderIsTheAccountNftContract(uint256 marginValueUsd) external {
        changePrank({ msgSender: users.naruto.account });

        marginValueUsd = bound({
            x: marginValueUsd,
            min: WSTETH_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(wstEth), WSTETH_DEPOSIT_CAP_X18)
        });
        deal({ token: address(wstEth), to: users.naruto.account, give: marginValueUsd });

        uint128 tradingAccountId = createAccountAndDeposit(marginValueUsd, address(wstEth));

        changePrank({ msgSender: address(tradingAccountToken) });

        // it should transfer the trading account token
        perpsEngine.notifyAccountTransfer(users.madara.account, tradingAccountId);

        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.AccountPermissionDenied.selector, tradingAccountId, users.naruto.account
            )
        });

        // old user cannot withdraw
        changePrank({ msgSender: users.naruto.account });
        perpsEngine.withdrawMargin(tradingAccountId, address(wstEth), marginValueUsd);

        // new user can withdraw
        changePrank({ msgSender: users.madara.account });
        perpsEngine.withdrawMargin(tradingAccountId, address(wstEth), marginValueUsd);
    }
}
