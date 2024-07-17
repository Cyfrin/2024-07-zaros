// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";

contract GetCustomReferralCode_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
    }

    function testFuzz_WhenGetCustomReferralCodeIsCalled(
        address referrer,
        string memory customReferralCode
    )
        external
    {
        changePrank({ msgSender: users.owner.account });
        perpsEngine.createCustomReferralCode(referrer, customReferralCode);

        changePrank({ msgSender: users.naruto.account });

        // it should the address of the referrer
        address referrerReceived = perpsEngine.getCustomReferralCodeReferrer(customReferralCode);
        assertEq(referrerReceived, referrer, "Referrer not set correctly");
    }
}
