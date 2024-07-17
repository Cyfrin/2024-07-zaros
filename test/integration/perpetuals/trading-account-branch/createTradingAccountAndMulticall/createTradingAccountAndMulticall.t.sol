// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { TradingAccountBranch } from "@zaros/perpetuals/branches/TradingAccountBranch.sol";
import { Base_Test } from "test/Base.t.sol";

contract CreateTradingAccountAndMulticall_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
    }

    function test_RevertWhen_TheDataArrayProvidesARevertingCall() external {
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(TradingAccountBranch.depositMargin.selector, address(usdc), uint256(0));

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "amount") });
        perpsEngine.createTradingAccountAndMulticall(data, bytes(""), false);
    }

    modifier whenTheDataArrayDoesNotProvideARevertingCall() {
        _;
    }

    function test_WhenTheDataArrayIsNull() external whenTheDataArrayDoesNotProvideARevertingCall {
        bytes[] memory data = new bytes[](0);
        uint128 expectedAccountId = 1;
        uint256 expectedResultsLength = 0;

        // it should emit {LogCreateTradingAccount}
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit TradingAccountBranch.LogCreateTradingAccount(expectedAccountId, users.naruto.account);

        bytes[] memory results = perpsEngine.createTradingAccountAndMulticall(data, bytes(""), false);
        // it should return a null results array
        assertEq(results.length, expectedResultsLength, "createTradingAccountAndMulticall");
    }

    function test_WhenTheDataArrayIsNotNull() external whenTheDataArrayDoesNotProvideARevertingCall {
        bytes[] memory data = new bytes[](1);
        uint128 expectedAccountId = 1;
        data[0] = abi.encodeWithSelector(TradingAccountBranch.getTradingAccountToken.selector);

        // it should emit {LogCreateTradingAccount}
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit TradingAccountBranch.LogCreateTradingAccount(expectedAccountId, users.naruto.account);

        bytes[] memory results = perpsEngine.createTradingAccountAndMulticall(data, bytes(""), false);
        address tradingAccountTokenReturned = abi.decode(results[0], (address));

        // it should return a valid results array
        assertEq(tradingAccountTokenReturned, address(tradingAccountToken), "createTradingAccountAndMulticall");
    }

    function testFuzz_CreateTradingAccountAndDepositMargin(uint256 amountToDeposit)
        external
        whenTheDataArrayDoesNotProvideARevertingCall
    {
        amountToDeposit = bound({
            x: amountToDeposit,
            min: 1,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });
        deal({ token: address(usdc), to: users.naruto.account, give: amountToDeposit });

        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(TradingAccountBranch.depositMargin.selector, address(usdc), amountToDeposit);
        uint128 expectedAccountId = 1;

        // it should transfer the amount from the sender to the trading account
        expectCallToTransferFrom(usdc, users.naruto.account, address(perpsEngine), amountToDeposit);
        bytes[] memory results = perpsEngine.createTradingAccountAndMulticall(data, bytes(""), false);

        uint256 newMarginCollateralBalance = convertUd60x18ToTokenAmount(
            address(usdc), perpsEngine.getAccountMarginCollateralBalance(expectedAccountId, address(usdc))
        );

        // it should increase the amount of margin collateral
        assertEq(results.length, 1, "createTradingAccountAndMulticall: results");
        assertEq(newMarginCollateralBalance, amountToDeposit, "createTradingAccountAndMulticall: account margin");
    }

    modifier whenTheUserHasAReferralCode() {
        _;
    }

    modifier whenTheReferralCodeIsCustom() {
        _;
    }

    function test_RevertWhen_TheReferralCodeIsInvalid()
        external
        whenTheDataArrayDoesNotProvideARevertingCall
        whenTheUserHasAReferralCode
        whenTheReferralCodeIsCustom
    {
        bytes[] memory data = new bytes[](0);

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.InvalidReferralCode.selector) });

        perpsEngine.createTradingAccountAndMulticall(data, bytes("customReferralCode"), true);
    }

    function test_WhenTheReferralCodeIsValid()
        external
        whenTheDataArrayDoesNotProvideARevertingCall
        whenTheUserHasAReferralCode
        whenTheReferralCodeIsCustom
    {
        bytes[] memory data = new bytes[](0);

        string memory customReferralCode = "customReferralCode";
        changePrank({ msgSender: users.owner.account });
        perpsEngine.createCustomReferralCode(users.owner.account, customReferralCode);

        changePrank({ msgSender: users.naruto.account });

        // it should emit {LogReferralSet} event
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit TradingAccountBranch.LogReferralSet(
            users.naruto.account, users.owner.account, bytes(customReferralCode), true
        );

        perpsEngine.createTradingAccountAndMulticall(data, bytes(customReferralCode), true);
    }

    modifier whenTheReferralCodeIsNotCustom() {
        _;
    }

    function test_RevertWhen_TheReferralCodeIsEqualToMsgSender()
        external
        whenTheDataArrayDoesNotProvideARevertingCall
        whenTheUserHasAReferralCode
        whenTheReferralCodeIsNotCustom
    {
        bytes[] memory data = new bytes[](0);

        string memory customReferralCode = "customReferralCode";
        changePrank({ msgSender: users.owner.account });
        perpsEngine.createCustomReferralCode(users.naruto.account, customReferralCode);

        changePrank({ msgSender: users.naruto.account });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.InvalidReferralCode.selector) });

        bytes memory referralCode = abi.encode(users.naruto.account);

        perpsEngine.createTradingAccountAndMulticall(data, referralCode, false);
    }

    function test_WhenTheReferralCodeIsNotEqualToMsgSender()
        external
        whenTheDataArrayDoesNotProvideARevertingCall
        whenTheUserHasAReferralCode
        whenTheReferralCodeIsNotCustom
    {
        bytes[] memory data = new bytes[](0);

        string memory customReferralCode = "customReferralCode";
        changePrank({ msgSender: users.owner.account });
        perpsEngine.createCustomReferralCode(users.naruto.account, customReferralCode);

        changePrank({ msgSender: users.naruto.account });

        bytes memory referralCode = abi.encode(users.owner.account);

        // it should emit {LogReferralSet} event
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit TradingAccountBranch.LogReferralSet(users.naruto.account, users.owner.account, referralCode, false);

        perpsEngine.createTradingAccountAndMulticall(data, referralCode, false);
    }
}
