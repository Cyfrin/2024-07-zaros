// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { TradingAccountBranch } from "@zaros/perpetuals/branches/TradingAccountBranch.sol";
import { TradingAccount } from "@zaros/perpetuals/leaves/TradingAccount.sol";
import { CustomReferralConfigurationTestnet } from "../leaves/CustomReferralConfigurationTestnet.sol";
import { ReferralTestnet } from "../leaves/ReferralTestnet.sol";

// Open Zeppelin dependencies
import { IERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { Initializable } from "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

// PRB Math dependencies
import { UD60x18, ud60x18 } from "@prb-math/UD60x18.sol";

contract TradingAccountBranchTestnet is TradingAccountBranch, Initializable, OwnableUpgradeable {
    using TradingAccount for TradingAccount.Data;
    using ReferralTestnet for ReferralTestnet.Data;

    mapping(address user => bool accountCreated) internal isAccountCreated;

    error UserAlreadyHasAccount();
    error FaucetAlreadyDeposited();

    constructor() {
        _disableInitializers();
    }

    function isUserAccountCreated(address user) external view returns (bool) {
        return isAccountCreated[user];
    }

    function createTradingAccount(bytes memory referralCode, bool isCustomReferralCode) public override returns (uint128) {
        bool userHasAccount = isAccountCreated[msg.sender];
        if (userHasAccount) {
            revert UserAlreadyHasAccount();
        }

        uint128 tradingAccountId = super.createTradingAccount(referralCode, isCustomReferralCode);
        isAccountCreated[msg.sender] = true;

        return tradingAccountId;
    }

    function depositMargin(
        uint128 tradingAccountId,
        address collateralType,
        uint256 amount
    )
        public
        virtual
        override
    {
        super.depositMargin(tradingAccountId, collateralType, amount);

        TradingAccount.Data storage tradingAccount = TradingAccount.loadExisting(tradingAccountId);
        UD60x18 marginCollateralBalance = tradingAccount.getMarginCollateralBalance(collateralType);

        if (marginCollateralBalance > ud60x18(100_000e18)) {
            revert FaucetAlreadyDeposited();
        }
    }
}
