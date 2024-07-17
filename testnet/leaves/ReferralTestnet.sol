// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { CustomReferralConfigurationTestnet } from "./CustomReferralConfigurationTestnet.sol";

library ReferralTestnet {
    string internal constant REFERRAL_TESTNET_DOMAIN = "fi.zaros.ReferralTestnet";

    struct Data {
        bytes referralCode;
        bool isCustomReferralCode;
    }

    function load(address accountOwner) internal pure returns (Data storage referralTestnet) {
        bytes32 slot = keccak256(abi.encode(REFERRAL_TESTNET_DOMAIN, accountOwner));

        assembly {
            referralTestnet.slot := slot
        }
    }

    function getReferrerAddress(Data storage self) internal view returns (address referrer) {
        if (!self.isCustomReferralCode) {
            referrer = abi.decode(self.referralCode, (address));
        } else {
            referrer = CustomReferralConfigurationTestnet.load(string(self.referralCode)).referrer;
        }
    }
}
