// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { RootProxy } from "@zaros/tree-proxy/RootProxy.sol";
import { GlobalConfigurationBranchTestnet } from "testnet/branches/GlobalConfigurationBranchTestnet.sol";
import { TradingAccountBranchTestnet } from "testnet/branches/TradingAccountBranchTestnet.sol";
import { TradingAccountBranch } from "@zaros/perpetuals/branches/TradingAccountBranch.sol";
import { PerpMarketBranch } from "@zaros/perpetuals/branches/PerpMarketBranch.sol";
import { GlobalConfigurationBranch } from "@zaros/perpetuals/branches/GlobalConfigurationBranch.sol";
import { SettlementBranch } from "@zaros/perpetuals/branches/SettlementBranch.sol";
import { OrderBranch } from "@zaros/perpetuals/branches/OrderBranch.sol";
import { PerpsEngine } from "@zaros/perpetuals/PerpsEngine.sol";
import { IPerpsEngine } from "@zaros/perpetuals/PerpsEngine.sol";
import { BaseScript } from "../Base.s.sol";
import { deployBranches, getBranchesSelectors, getBranchUpgrades } from "../utils/TreeProxyUtils.sol";

// Open Zeppelin dependencies
import { ERC1967Proxy } from "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import { UUPSUpgradeable } from "@openzeppelin/proxy/utils/UUPSUpgradeable.sol";

// Forge dependencies
import { console } from "forge-std/console.sol";

contract UpgradeBranches is BaseScript {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/
    IPerpsEngine internal perpsEngine;

    function run() public broadcaster {
        // TradingAccountBranchTestnet tradingAccountBranchTestnet = new TradingAccountBranchTestnet();
        // PerpMarketBranch perpMarketBranch = new PerpMarketBranch();
        // GlobalConfigurationBranchTestnet globalConfigurationBranchTestnet = new GlobalConfigurationBranchTestnet();
        SettlementBranch settlementBranch = new SettlementBranch();
        // OrderBranch orderBranch = new OrderBranch();

        // bytes4[] memory tradingAccountBranchTestnetSelectorsAdded = new bytes4[](1);
        // bytes4[] memory tradingAccountBranchTestnetSelectorsUpdated = new bytes4[](3);
        // bytes4[] memory globalConfigurationBranchTestnetSelectorsAdded = new bytes4[](1);
        bytes4[] memory settlementBranchSelectorsUpdated = new bytes4[](1);
        // bytes4[] memory orderBranchTestnetSelectorsUpdated = new bytes4[](1);

        // RootProxy.BranchUpgrade[] memory branchUpgrades = new RootProxy.BranchUpgrade[](4);

        // bytes4[] memory globalConfigurationBranchTestnetSelectorsAdded = new bytes4[](1);
        // bytes4[] memory perpMarketBranchSelectorsUpdated = new bytes4[](1);

        RootProxy.BranchUpgrade[] memory branchUpgrades = new RootProxy.BranchUpgrade[](1);

        address[] memory initializables;
        bytes[] memory initializePayloads;

        // tradingAccountBranchTestnetSelectorsAdded[0] = TradingAccountBranch.getPositionState.selector;
        // tradingAccountBranchTestnetSelectorsAdded[1] = bytes4(keccak256("createTradingAccount(bytes,bool)"));
        // tradingAccountBranchTestnetSelectorsAdded[2] = TradingAccountBranchTestnet.getPointsOfUser.selector;
        // tradingAccountBranchTestnetSelectorsAdded[3] = TradingAccountBranchTestnet.getUserReferralData.selector;
        // tradingAccountBranchTestnetSelectorsAdded[4] =
        // TradingAccountBranchTestnet.getCustomReferralCodeReferee.selector;

        // tradingAccountBranchTestnetSelectorsUpdated[0] = TradingAccountBranch.getAccountMarginBreakdown.selector;
        // tradingAccountBranchTestnetSelectorsUpdated[1] = TradingAccountBranch.getAccountEquityUsd.selector;
        // tradingAccountBranchTestnetSelectorsUpdated[2] = TradingAccountBranch.getAccountLeverage.selector;

        // tradingAccountBranchTestnetSelectorsUpdated[0] = TradingAccountBranchTestnet.getUserReferralData.selector;
        // tradingAccountBranchTestnetSelectorsUpdated[1] =
        // bytes4(keccak256("createTradingAccountAndMulticall(bytes[])"));
        // tradingAccountBranchTestnetSelectorsUpdated[2] =
        // bytes4(keccak256("depositMargin(uint128,address,uint256)"));

        // globalConfigurationBranchTestnetSelectorsAdded[0] =
        //     GlobalConfigurationBranchTestnet.getCustomReferralCodeReferrer.selector;
        // globalConfigurationBranchTestnetSelectorsAdded[1] =
        //     GlobalConfigurationBranchTestnet.createCustomReferralCode.selector;

        settlementBranchSelectorsUpdated[0] = SettlementBranch.fillMarketOrder.selector;

        // globalConfigurationBranchTestnetSelectorsAdded[0] =
        //     GlobalConfigurationBranch.updateSettlementConfiguration.selector;

        // perpMarketBranchSelectorsUpdated[0] = PerpMarketBranch.getOpenInterest.selector;

        // orderBranchTestnetSelectorsUpdated[0] = OrderBranch.createMarketOrder.selector;

        branchUpgrades[0] = (
            RootProxy.BranchUpgrade({
                branch: address(settlementBranch),
                action: RootProxy.BranchUpgradeAction.Replace,
                selectors: settlementBranchSelectorsUpdated
            })
        );

        // branchUpgrades[0] = (
        //     RootProxy.BranchUpgrade({
        //         branch: address(tradingAccountBranchTestnet),
        //         action: RootProxy.BranchUpgradeAction.Add,
        //         selectors: tradingAccountBranchTestnetSelectorsAdded
        //     })
        // );

        // branchUpgrades[1] = (
        //     RootProxy.BranchUpgrade({
        //         branch: address(tradingAccountBranchTestnet),
        //         action: RootProxy.BranchUpgradeAction.Replace,
        //         selectors: tradingAccountBranchTestnetSelectorsUpdated
        //     })
        // );

        // branchUpgrades[2] = (
        //     RootProxy.BranchUpgrade({
        //         branch: address(globalConfigurationBranchTestnet),
        //         action: RootProxy.BranchUpgradeAction.Add,
        //         selectors: globalConfigurationBranchTestnetSelectorsAdded
        //     })
        // );

        perpsEngine = IPerpsEngine(vm.envAddress("PERPS_ENGINE"));

        perpsEngine.upgrade(branchUpgrades, initializables, initializePayloads);
    }
}
