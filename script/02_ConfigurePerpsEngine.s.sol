// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { AccountNFT } from "@zaros/account-nft/AccountNFT.sol";
import { IPerpsEngine } from "@zaros/perpetuals/PerpsEngine.sol";
import { LimitedMintingERC20 } from "testnet/LimitedMintingERC20.sol";
import { BaseScript } from "./Base.s.sol";
import { ChainlinkAutomationUtils } from "./utils/ChainlinkAutomationUtils.sol";
import { ProtocolConfiguration } from "./utils/ProtocolConfiguration.sol";

// Forge dependencies
import { console } from "forge-std/console.sol";

contract ConfigurePerpsEngine is BaseScript, ProtocolConfiguration {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/
    uint256 internal keeperInitialLinkFunding;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/
    AccountNFT internal tradingAccountToken;
    address internal link;
    address internal automationRegistrar;
    IPerpsEngine internal perpsEngine;

    function run(uint256 initialMarginCollateralId, uint256 finalMarginCollateralId) public broadcaster {
        tradingAccountToken = AccountNFT(vm.envAddress("TRADING_ACCOUNT_NFT"));
        perpsEngine = IPerpsEngine(vm.envAddress("PERPS_ENGINE"));
        link = vm.envAddress("LINK");
        automationRegistrar = vm.envAddress("CHAINLINK_AUTOMATION_REGISTRAR");
        keeperInitialLinkFunding = vm.envUint("KEEPER_INITIAL_LINK_FUNDING");

        configureContracts(initialMarginCollateralId, finalMarginCollateralId);
    }

    function configureContracts(uint256 initialMarginCollateralId, uint256 finalMarginCollateralId) internal {
        tradingAccountToken.transferOwnership(address(perpsEngine));

        perpsEngine.setTradingAccountToken(address(tradingAccountToken));

        configureSequencerUptimeFeeds(perpsEngine);

        perpsEngine.configureSystemParameters({
            maxPositionsPerAccount: MAX_POSITIONS_PER_ACCOUNT,
            marketOrderMinLifetime: MARKET_ORDER_MIN_LIFETIME,
            liquidationFeeUsdX18: LIQUIDATION_FEE_USD,
            marginCollateralRecipient: MSIG_ADDRESS,
            orderFeeRecipient: MSIG_ADDRESS,
            settlementFeeRecipient: MSIG_ADDRESS,
            liquidationFeeRecipient: MSIG_ADDRESS,
            maxVerificationDelay: MAX_VERIFICATION_DELAY
        });

        uint256[2] memory marginCollateralIdsRange;
        marginCollateralIdsRange[0] = initialMarginCollateralId;
        marginCollateralIdsRange[1] = finalMarginCollateralId;

        configureMarginCollaterals(perpsEngine, marginCollateralIdsRange, false, address(0));

        address liquidationKeeper = ChainlinkAutomationUtils.deployLiquidationKeeper(deployer, address(perpsEngine));
        console.log("Liquidation Keeper: ", liquidationKeeper);

        address[] memory liquidators = new address[](1);
        bool[] memory liquidatorStatus = new bool[](1);

        liquidators[0] = liquidationKeeper;
        liquidatorStatus[0] = true;

        perpsEngine.configureLiquidators(liquidators, liquidatorStatus);

        LimitedMintingERC20(USDZ_ADDRESS).transferOwnership(address(perpsEngine));
    }
}
