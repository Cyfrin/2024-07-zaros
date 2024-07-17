// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

library CustomReferralConfiguration {
    string internal constant CUSTOM_REFERRAL_CONFIGURATION_DOMAIN = "fi.zaros.CustomReferralConfiguration";

    struct Data {
        address referrer;
    }

    function load(string memory customReferralCode)
        internal
        pure
        returns (Data storage customReferralConfigurationTestnet)
    {
        bytes32 slot = keccak256(abi.encode(CUSTOM_REFERRAL_CONFIGURATION_DOMAIN, customReferralCode));

        assembly {
            customReferralConfigurationTestnet.slot := slot
        }
    }
}
