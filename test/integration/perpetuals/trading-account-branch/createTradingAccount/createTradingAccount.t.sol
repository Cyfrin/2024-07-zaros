// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { TradingAccountBranch } from "@zaros/perpetuals/branches/TradingAccountBranch.sol";
import { Errors } from "@zaros/utils/Errors.sol";

contract CreateTradingAccount_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
    }

    function test_RevertGiven_TheTradingAccountTokenIsNotSet() external {
        bytes32 slot = bytes32(uint256(GLOBAL_CONFIGURATION_LOCATION) + uint256(7));
        vm.store(address(perpsEngine), slot, bytes32(uint256(0)));

        // it should revert
        vm.expectRevert();
        perpsEngine.createTradingAccount(bytes(""), false);
    }

    modifier givenTheTradingAccountTokenIsSet() {
        _;
    }

    function test_GivenTheCallerHasNoPreviousTradingAccount() external givenTheTradingAccountTokenIsSet {
        uint128 expectedAccountId = 1;

        // it should emit {LogCreateTradingAccount}
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit TradingAccountBranch.LogCreateTradingAccount(expectedAccountId, users.naruto.account);

        uint128 tradingAccountId = perpsEngine.createTradingAccount(bytes(""), false);

        // it should return a valid tradingAccountId
        assertEq(tradingAccountId, expectedAccountId, "createTradingAccount");
    }

    function test_GivenTheCallerHasAPreviouslyCreatedTradingAccount() external givenTheTradingAccountTokenIsSet {
        uint128 expectedAccountId = 2;
        perpsEngine.createTradingAccount(bytes(""), false);

        // it should emit {LogCreateTradingAccount}
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit TradingAccountBranch.LogCreateTradingAccount(expectedAccountId, users.naruto.account);
        uint128 tradingAccountId = perpsEngine.createTradingAccount(bytes(""), false);

        // it should return a valid tradingAccountId
        assertEq(tradingAccountId, expectedAccountId, "createTradingAccount");
    }

    modifier whenTheUserHasAReferralCode() {
        _;
    }

    modifier whenTheReferralCodeIsCustom() {
        _;
    }

    function test_RevertWhen_TheReferralCodeIsInvalid()
        external
        givenTheTradingAccountTokenIsSet
        whenTheUserHasAReferralCode
        whenTheReferralCodeIsCustom
    {
        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.InvalidReferralCode.selector) });

        perpsEngine.createTradingAccount(bytes("customReferralCode"), true);
    }

    function test_WhenTheReferralCodeIsValid()
        external
        givenTheTradingAccountTokenIsSet
        whenTheUserHasAReferralCode
        whenTheReferralCodeIsCustom
    {
        string memory customReferralCode = "customReferralCode";
        changePrank({ msgSender: users.owner.account });
        perpsEngine.createCustomReferralCode(users.owner.account, customReferralCode);

        changePrank({ msgSender: users.naruto.account });

        // it should emit {LogReferralSet} event
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit TradingAccountBranch.LogReferralSet(
            users.naruto.account, users.owner.account, bytes(customReferralCode), true
        );

        perpsEngine.createTradingAccount(bytes(customReferralCode), true);
    }

    modifier whenTheReferralCodeIsNotCustom() {
        _;
    }

    function test_RevertWhen_TheReferralCodeIsEqualToMsgSender()
        external
        givenTheTradingAccountTokenIsSet
        whenTheUserHasAReferralCode
        whenTheReferralCodeIsNotCustom
    {
        string memory customReferralCode = "customReferralCode";
        changePrank({ msgSender: users.owner.account });
        perpsEngine.createCustomReferralCode(users.naruto.account, customReferralCode);

        changePrank({ msgSender: users.naruto.account });

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.InvalidReferralCode.selector) });

        bytes memory referralCode = abi.encode(users.naruto.account);

        perpsEngine.createTradingAccount(referralCode, false);
    }

    function test_WhenTheReferralCodeIsNotEqualToMsgSender()
        external
        givenTheTradingAccountTokenIsSet
        whenTheUserHasAReferralCode
        whenTheReferralCodeIsNotCustom
    {
        string memory customReferralCode = "customReferralCode";
        changePrank({ msgSender: users.owner.account });
        perpsEngine.createCustomReferralCode(users.naruto.account, customReferralCode);

        changePrank({ msgSender: users.naruto.account });

        bytes memory referralCode = abi.encode(users.owner.account);

        // it should emit {LogReferralSet} event
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit TradingAccountBranch.LogReferralSet(users.naruto.account, users.owner.account, referralCode, false);

        perpsEngine.createTradingAccount(referralCode, false);
    }
}
