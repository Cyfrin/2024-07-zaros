// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { CustomReferralConfiguration } from "@zaros/perpetuals/leaves/CustomReferralConfiguration.sol";

library Referral {
    string internal constant REFERRAL_DOMAIN = "fi.zaros.Referral";

    struct Data {
        bytes referralCode;
        bool isCustomReferralCode;
    }

    function load(address accountOwner) internal pure returns (Data storage referralTestnet) {
        bytes32 slot = keccak256(abi.encode(REFERRAL_DOMAIN, accountOwner));

        assembly {
            referralTestnet.slot := slot
        }
    }

    function getReferrerAddress(Data storage self) internal view returns (address referrer) {
        if (!self.isCustomReferralCode) {
            referrer = abi.decode(self.referralCode, (address));
        } else {
            referrer = CustomReferralConfiguration.load(string(self.referralCode)).referrer;
        }
    }
}
