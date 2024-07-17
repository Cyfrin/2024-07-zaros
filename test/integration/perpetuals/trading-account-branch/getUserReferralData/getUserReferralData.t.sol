// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";

contract GetUserReferralData_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
    }

    function testFuzz_WhenGetUserReferralDataIsCalled(bool isCustomReferralCode) external {
        string memory customReferralCode = "customReferralCode";
        bytes memory bytesReferralCode;

        if (isCustomReferralCode) {
            changePrank({ msgSender: users.owner.account });
            perpsEngine.createCustomReferralCode(users.owner.account, "customReferralCode");
            bytesReferralCode = bytes(customReferralCode);
        } else {
            bytesReferralCode = abi.encode(users.owner.account);
        }

        changePrank({ msgSender: users.naruto.account });

        perpsEngine.createTradingAccount(bytesReferralCode, isCustomReferralCode);

        (bytes memory receivedReferralCode, bool receivedIsCustomReferralCode) =
            perpsEngine.getUserReferralData(users.naruto.account);

        // it should return the referral code
        assertEq(bytesReferralCode, receivedReferralCode, "referral code is not correct");

        // it should return if the referal code is custom
        assertEq(isCustomReferralCode, receivedIsCustomReferralCode, "isCustomReferralCode is not correct");
    }
}
