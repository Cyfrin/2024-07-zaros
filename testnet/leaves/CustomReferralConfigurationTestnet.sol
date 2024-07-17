// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

library CustomReferralConfigurationTestnet {
    string internal constant CUSTOM_REFERRAL_CONFIGURATION_TESTNET_DOMAIN =
        "fi.zaros.CustomReferralConfigurationTestnet";

    struct Data {
        address referrer;
    }

    function load(string memory customReferralCode)
        internal
        pure
        returns (Data storage customReferralConfigurationTestnet)
    {
        bytes32 slot = keccak256(abi.encode(CUSTOM_REFERRAL_CONFIGURATION_TESTNET_DOMAIN, customReferralCode));

        assembly {
            customReferralConfigurationTestnet.slot := slot
        }
    }
}
