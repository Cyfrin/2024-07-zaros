// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { RootProxy } from "@zaros/tree-proxy/RootProxy.sol";
import { UpgradeBranch } from "@zaros/tree-proxy/branches/UpgradeBranch.sol";
import { LookupBranch } from "@zaros/tree-proxy/branches/LookupBranch.sol";
import { GlobalConfigurationBranch } from "@zaros/perpetuals/branches/GlobalConfigurationBranch.sol";
import { LiquidationBranch } from "@zaros/perpetuals/branches/LiquidationBranch.sol";
import { OrderBranch } from "@zaros/perpetuals/branches/OrderBranch.sol";
import { PerpMarketBranch } from "@zaros/perpetuals/branches/PerpMarketBranch.sol";
import { TradingAccountBranch } from "@zaros/perpetuals/branches/TradingAccountBranch.sol";
import { SettlementBranch } from "@zaros/perpetuals/branches/SettlementBranch.sol";
import { GlobalConfigurationBranchTestnet } from "testnet/branches/GlobalConfigurationBranchTestnet.sol";
import { TradingAccountBranchTestnet } from "testnet/branches/TradingAccountBranchTestnet.sol";
import { GlobalConfigurationHarness } from "test/harnesses/perpetuals/leaves/GlobalConfigurationHarness.sol";
import { MarginCollateralConfigurationHarness } from
    "test/harnesses/perpetuals/leaves/MarginCollateralConfigurationHarness.sol";
import { MarketConfigurationHarness } from "test/harnesses/perpetuals/leaves/MarketConfigurationHarness.sol";
import { MarketOrderHarness } from "test/harnesses/perpetuals/leaves/MarketOrderHarness.sol";
import { PerpMarketHarness } from "test/harnesses/perpetuals/leaves/PerpMarketHarness.sol";
import { PositionHarness } from "test/harnesses/perpetuals/leaves/PositionHarness.sol";
import { SettlementConfigurationHarness } from "test/harnesses/perpetuals/leaves/SettlementConfigurationHarness.sol";
import { TradingAccountHarness } from "test/harnesses/perpetuals/leaves/TradingAccountHarness.sol";

// Open Zeppelin Upgradeable dependencies
import { EIP712Upgradeable } from "@openzeppelin-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

// Forge dependencies
import { console } from "forge-std/console.sol";

function deployBranches(bool isTestnet) returns (address[] memory) {
    address[] memory branches = new address[](8);

    address upgradeBranch = address(new UpgradeBranch());
    console.log("UpgradeBranch: ", upgradeBranch);

    address lookupBranch = address(new LookupBranch());
    console.log("LookupBranch: ", lookupBranch);

    address liquidationBranch = address(new LiquidationBranch());
    console.log("LiquidationBranch: ", liquidationBranch);

    address orderBranch = address(new OrderBranch());
    console.log("OrderBranch: ", orderBranch);

    address perpMarketBranch = address(new PerpMarketBranch());
    console.log("PerpMarketBranch: ", perpMarketBranch);

    address settlementBranch = address(new SettlementBranch());
    console.log("SettlementBranch: ", settlementBranch);

    address globalConfigurationBranch;
    address tradingAccountBranch;
    if (isTestnet) {
        globalConfigurationBranch = address(new GlobalConfigurationBranchTestnet());
        tradingAccountBranch = address(new TradingAccountBranchTestnet());
    } else {
        globalConfigurationBranch = address(new GlobalConfigurationBranch());
        tradingAccountBranch = address(new TradingAccountBranch());
    }
    console.log("GlobalConfigurationBranch: ", globalConfigurationBranch);
    console.log("TradingAccountBranch: ", tradingAccountBranch);

    branches[0] = upgradeBranch;
    branches[1] = lookupBranch;
    branches[2] = globalConfigurationBranch;
    branches[3] = liquidationBranch;
    branches[4] = orderBranch;
    branches[5] = perpMarketBranch;
    branches[6] = tradingAccountBranch;
    branches[7] = settlementBranch;

    return branches;
}

function getBranchesSelectors(bool isTestnet) pure returns (bytes4[][] memory) {
    bytes4[][] memory selectors = new bytes4[][](8);

    bytes4[] memory upgradeBranchSelectors = new bytes4[](1);

    upgradeBranchSelectors[0] = UpgradeBranch.upgrade.selector;

    bytes4[] memory lookupBranchSelectors = new bytes4[](4);

    lookupBranchSelectors[0] = LookupBranch.branches.selector;
    lookupBranchSelectors[1] = LookupBranch.branchFunctionSelectors.selector;
    lookupBranchSelectors[2] = LookupBranch.branchAddresses.selector;
    lookupBranchSelectors[3] = LookupBranch.branchAddress.selector;

    bytes4[] memory globalConfigurationBranchSelectors = new bytes4[](isTestnet ? 17 : 16);

    globalConfigurationBranchSelectors[0] = GlobalConfigurationBranch.getAccountsWithActivePositions.selector;
    globalConfigurationBranchSelectors[1] = GlobalConfigurationBranch.getMarginCollateralConfiguration.selector;
    globalConfigurationBranchSelectors[2] = GlobalConfigurationBranch.setTradingAccountToken.selector;
    globalConfigurationBranchSelectors[3] = GlobalConfigurationBranch.configureCollateralLiquidationPriority.selector;
    globalConfigurationBranchSelectors[4] = GlobalConfigurationBranch.configureLiquidators.selector;
    globalConfigurationBranchSelectors[5] = GlobalConfigurationBranch.configureMarginCollateral.selector;
    globalConfigurationBranchSelectors[6] = GlobalConfigurationBranch.removeCollateralFromLiquidationPriority.selector;
    globalConfigurationBranchSelectors[7] = GlobalConfigurationBranch.configureSystemParameters.selector;
    globalConfigurationBranchSelectors[8] = GlobalConfigurationBranch.createPerpMarket.selector;
    globalConfigurationBranchSelectors[9] = GlobalConfigurationBranch.updatePerpMarketConfiguration.selector;
    globalConfigurationBranchSelectors[10] = GlobalConfigurationBranch.updatePerpMarketStatus.selector;
    globalConfigurationBranchSelectors[11] = GlobalConfigurationBranch.updateSettlementConfiguration.selector;
    globalConfigurationBranchSelectors[12] = GlobalConfigurationBranch.setUsdToken.selector;
    globalConfigurationBranchSelectors[13] = GlobalConfigurationBranch.configureSequencerUptimeFeedByChainId.selector;
    globalConfigurationBranchSelectors[14] = GlobalConfigurationBranch.getCustomReferralCodeReferrer.selector;
    globalConfigurationBranchSelectors[15] = GlobalConfigurationBranch.createCustomReferralCode.selector;

    if (isTestnet) {
        globalConfigurationBranchSelectors[16] = GlobalConfigurationBranchTestnet.setUserPoints.selector;
    }

    bytes4[] memory liquidationBranchSelectors = new bytes4[](2);

    liquidationBranchSelectors[0] = LiquidationBranch.checkLiquidatableAccounts.selector;
    liquidationBranchSelectors[1] = LiquidationBranch.liquidateAccounts.selector;

    bytes4[] memory orderBranchSelectors = new bytes4[](7);

    orderBranchSelectors[0] = OrderBranch.getConfiguredOrderFees.selector;
    orderBranchSelectors[1] = OrderBranch.simulateTrade.selector;
    orderBranchSelectors[2] = OrderBranch.getMarginRequirementForTrade.selector;
    orderBranchSelectors[3] = OrderBranch.getActiveMarketOrder.selector;
    orderBranchSelectors[4] = OrderBranch.createMarketOrder.selector;
    orderBranchSelectors[5] = OrderBranch.cancelAllOffchainOrders.selector;
    orderBranchSelectors[6] = OrderBranch.cancelMarketOrder.selector;

    bytes4[] memory perpMarketBranchSelectors = new bytes4[](11);

    perpMarketBranchSelectors[0] = PerpMarketBranch.getName.selector;
    perpMarketBranchSelectors[1] = PerpMarketBranch.getSymbol.selector;
    perpMarketBranchSelectors[2] = PerpMarketBranch.getMaxOpenInterest.selector;
    perpMarketBranchSelectors[3] = PerpMarketBranch.getMaxSkew.selector;
    perpMarketBranchSelectors[4] = PerpMarketBranch.getSkew.selector;
    perpMarketBranchSelectors[5] = PerpMarketBranch.getOpenInterest.selector;
    perpMarketBranchSelectors[6] = PerpMarketBranch.getMarkPrice.selector;
    perpMarketBranchSelectors[7] = PerpMarketBranch.getSettlementConfiguration.selector;
    perpMarketBranchSelectors[8] = PerpMarketBranch.getFundingRate.selector;
    perpMarketBranchSelectors[9] = PerpMarketBranch.getFundingVelocity.selector;
    perpMarketBranchSelectors[10] = PerpMarketBranch.getPerpMarketConfiguration.selector;

    bytes4[] memory tradingAccountBranchSelectors = new bytes4[](isTestnet ? 14 : 13);

    tradingAccountBranchSelectors[0] = TradingAccountBranch.getTradingAccountToken.selector;
    tradingAccountBranchSelectors[1] = TradingAccountBranch.getAccountMarginCollateralBalance.selector;
    tradingAccountBranchSelectors[2] = TradingAccountBranch.getAccountEquityUsd.selector;
    tradingAccountBranchSelectors[3] = TradingAccountBranch.getAccountMarginBreakdown.selector;
    tradingAccountBranchSelectors[4] = TradingAccountBranch.getAccountTotalUnrealizedPnl.selector;
    tradingAccountBranchSelectors[5] = TradingAccountBranch.getAccountLeverage.selector;
    tradingAccountBranchSelectors[6] = TradingAccountBranch.getPositionState.selector;
    tradingAccountBranchSelectors[7] = TradingAccountBranch.createTradingAccount.selector;
    tradingAccountBranchSelectors[8] = TradingAccountBranch.createTradingAccountAndMulticall.selector;
    tradingAccountBranchSelectors[9] = TradingAccountBranch.depositMargin.selector;
    tradingAccountBranchSelectors[10] = TradingAccountBranch.withdrawMargin.selector;
    tradingAccountBranchSelectors[11] = TradingAccountBranch.notifyAccountTransfer.selector;
    tradingAccountBranchSelectors[12] = TradingAccountBranch.getUserReferralData.selector;

    if (isTestnet) {
        tradingAccountBranchSelectors[7] = bytes4(keccak256("createTradingAccount(bytes,bool)"));
        tradingAccountBranchSelectors[8] = bytes4(keccak256("createTradingAccountAndMulticall(bytes[],bytes,bool)"));
        tradingAccountBranchSelectors[13] = TradingAccountBranchTestnet.isUserAccountCreated.selector;
    }

    bytes4[] memory settlementBranchSelectors = new bytes4[](4);

    settlementBranchSelectors[0] = EIP712Upgradeable.eip712Domain.selector;
    settlementBranchSelectors[1] = SettlementBranch.DOMAIN_SEPARATOR.selector;
    settlementBranchSelectors[2] = SettlementBranch.fillMarketOrder.selector;
    settlementBranchSelectors[3] = SettlementBranch.fillOffchainOrders.selector;

    selectors[0] = upgradeBranchSelectors;
    selectors[1] = lookupBranchSelectors;
    selectors[2] = globalConfigurationBranchSelectors;
    selectors[3] = liquidationBranchSelectors;
    selectors[4] = orderBranchSelectors;
    selectors[5] = perpMarketBranchSelectors;
    selectors[6] = tradingAccountBranchSelectors;
    selectors[7] = settlementBranchSelectors;

    return selectors;
}

function getBranchUpgrades(
    address[] memory branches,
    bytes4[][] memory branchesSelectors,
    RootProxy.BranchUpgradeAction action
)
    pure
    returns (RootProxy.BranchUpgrade[] memory)
{
    require(branches.length == branchesSelectors.length, "TreeProxyUtils: branchesSelectors length mismatch");
    RootProxy.BranchUpgrade[] memory branchUpgrades = new RootProxy.BranchUpgrade[](branches.length);

    for (uint256 i; i < branches.length; i++) {
        bytes4[] memory selectors = branchesSelectors[i];

        branchUpgrades[i] = RootProxy.BranchUpgrade({ branch: branches[i], action: action, selectors: selectors });
    }

    return branchUpgrades;
}

function getInitializables(address[] memory branches) pure returns (address[] memory) {
    address[] memory initializables = new address[](2);

    address upgradeBranch = branches[0];
    address globalConfigurationBranch = branches[2];

    initializables[0] = upgradeBranch;
    initializables[1] = globalConfigurationBranch;

    return initializables;
}

function getInitializePayloads(
    address deployer,
    address tradingAccountToken,
    address usdToken
)
    pure
    returns (bytes[] memory)
{
    bytes[] memory initializePayloads = new bytes[](2);

    bytes memory rootUpgradeInitializeData = abi.encodeWithSelector(UpgradeBranch.initialize.selector, deployer);
    bytes memory perpsEngineInitializeData =
        abi.encodeWithSelector(GlobalConfigurationBranch.initialize.selector, tradingAccountToken, usdToken);

    initializePayloads = new bytes[](2);

    initializePayloads[0] = rootUpgradeInitializeData;
    initializePayloads[1] = perpsEngineInitializeData;

    return initializePayloads;
}

function deployHarnesses(RootProxy.BranchUpgrade[] memory branchUpgrades)
    returns (RootProxy.BranchUpgrade[] memory)
{
    address[] memory harnesses = deployAddressHarnesses();

    bytes4[][] memory harnessesSelectors = getHarnessesSelectors();

    RootProxy.BranchUpgrade[] memory harnessesUpgrades =
        getBranchUpgrades(harnesses, harnessesSelectors, RootProxy.BranchUpgradeAction.Add);

    uint256 cachedBranchUpgradesLength = branchUpgrades.length;

    uint256 maxLength = cachedBranchUpgradesLength + harnessesUpgrades.length;

    RootProxy.BranchUpgrade[] memory brancheAndHarnessesUpgrades = new RootProxy.BranchUpgrade[](maxLength);

    for (uint256 i; i < maxLength; i++) {
        brancheAndHarnessesUpgrades[i] =
            i < cachedBranchUpgradesLength ? branchUpgrades[i] : harnessesUpgrades[i - cachedBranchUpgradesLength];
    }

    return brancheAndHarnessesUpgrades;
}

function deployAddressHarnesses() returns (address[] memory) {
    address[] memory addressHarnesses = new address[](8);

    address globalConfigurationHarness = address(new GlobalConfigurationHarness());
    console.log("GlobalConfigurationHarness: ", globalConfigurationHarness);

    address marginCollateralConfigurationHarness = address(new MarginCollateralConfigurationHarness());
    console.log("MarginCollateralConfigurationHarness: ", marginCollateralConfigurationHarness);

    address marketConfigurationHarness = address(new MarketConfigurationHarness());
    console.log("MarketConfigurationHarness: ", marketConfigurationHarness);

    address marketOrderHarness = address(new MarketOrderHarness());
    console.log("MarketOrderHarness: ", marketOrderHarness);

    address perpMarketHarness = address(new PerpMarketHarness());
    console.log("PerpMarketHarness: ", perpMarketHarness);

    address positionHarness = address(new PositionHarness());
    console.log("PositionHarness: ", positionHarness);

    address settlementConfigurationHarness = address(new SettlementConfigurationHarness());
    console.log("SettlementConfigurationHarness: ", settlementConfigurationHarness);

    address tradingAccountHarness = address(new TradingAccountHarness());
    console.log("TradingAccountHarness: ", tradingAccountHarness);

    addressHarnesses[0] = globalConfigurationHarness;
    addressHarnesses[1] = marginCollateralConfigurationHarness;
    addressHarnesses[2] = marketConfigurationHarness;
    addressHarnesses[3] = marketOrderHarness;
    addressHarnesses[4] = perpMarketHarness;
    addressHarnesses[5] = positionHarness;
    addressHarnesses[6] = settlementConfigurationHarness;
    addressHarnesses[7] = tradingAccountHarness;

    return addressHarnesses;
}

function getHarnessesSelectors() pure returns (bytes4[][] memory) {
    bytes4[][] memory selectors = new bytes4[][](8);

    bytes4[] memory globalConfigurationHarnessSelectors = new bytes4[](11);
    globalConfigurationHarnessSelectors[0] = GlobalConfigurationHarness.exposed_checkMarketIsEnabled.selector;
    globalConfigurationHarnessSelectors[1] = GlobalConfigurationHarness.exposed_addMarket.selector;
    globalConfigurationHarnessSelectors[2] = GlobalConfigurationHarness.exposed_removeMarket.selector;
    globalConfigurationHarnessSelectors[3] =
        GlobalConfigurationHarness.exposed_configureCollateralLiquidationPriority.selector;
    globalConfigurationHarnessSelectors[4] =
        GlobalConfigurationHarness.exposed_removeCollateralFromLiquidationPriority.selector;
    globalConfigurationHarnessSelectors[5] =
        GlobalConfigurationHarness.workaround_getAccountIdWithActivePositions.selector;
    globalConfigurationHarnessSelectors[6] =
        GlobalConfigurationHarness.workaround_getAccountsIdsWithActivePositionsLength.selector;
    globalConfigurationHarnessSelectors[7] = GlobalConfigurationHarness.workaround_getTradingAccountToken.selector;
    globalConfigurationHarnessSelectors[8] = GlobalConfigurationHarness.workaround_getUsdToken.selector;
    globalConfigurationHarnessSelectors[9] =
        GlobalConfigurationHarness.workaround_getCollateralLiquidationPriority.selector;
    globalConfigurationHarnessSelectors[10] =
        GlobalConfigurationHarness.workaround_getSequencerUptimeFeedByChainId.selector;

    bytes4[] memory marginCollateralConfigurationHarnessSelectors = new bytes4[](6);
    marginCollateralConfigurationHarnessSelectors[0] =
        MarginCollateralConfigurationHarness.exposed_MarginCollateral_load.selector;
    marginCollateralConfigurationHarnessSelectors[1] =
        MarginCollateralConfigurationHarness.exposed_convertTokenAmountToUd60x18.selector;
    marginCollateralConfigurationHarnessSelectors[2] =
        MarginCollateralConfigurationHarness.exposed_convertUd60x18ToTokenAmount.selector;
    marginCollateralConfigurationHarnessSelectors[3] = MarginCollateralConfigurationHarness.exposed_getPrice.selector;
    marginCollateralConfigurationHarnessSelectors[4] = MarginCollateralConfigurationHarness.exposed_configure.selector;
    marginCollateralConfigurationHarnessSelectors[5] =
        MarginCollateralConfigurationHarness.workaround_getTotalDeposited.selector;

    bytes4[] memory marketConfigurationHarnessSelectors = new bytes4[](1);
    marketConfigurationHarnessSelectors[0] = MarketConfigurationHarness.exposed_update.selector;

    bytes4[] memory marketOrderHarnessSelectors = new bytes4[](5);
    marketOrderHarnessSelectors[0] = MarketOrderHarness.exposed_MarketOrder_load.selector;
    marketOrderHarnessSelectors[1] = MarketOrderHarness.exposed_MarketOrder_loadExisting.selector;
    marketOrderHarnessSelectors[2] = MarketOrderHarness.exposed_update.selector;
    marketOrderHarnessSelectors[3] = MarketOrderHarness.exposed_clear.selector;
    marketOrderHarnessSelectors[4] = MarketOrderHarness.exposed_checkPendingOrder.selector;

    bytes4[] memory perpMarketHarnessSelectors = new bytes4[](14);
    perpMarketHarnessSelectors[0] = PerpMarketHarness.exposed_PerpMarket_load.selector;
    perpMarketHarnessSelectors[1] = PerpMarketHarness.exposed_getIndexPrice.selector;
    perpMarketHarnessSelectors[2] = PerpMarketHarness.exposed_getMarkPrice.selector;
    perpMarketHarnessSelectors[3] = PerpMarketHarness.exposed_getCurrentFundingRate.selector;
    perpMarketHarnessSelectors[4] = PerpMarketHarness.exposed_getCurrentFundingVelocity.selector;
    perpMarketHarnessSelectors[5] = PerpMarketHarness.exposed_getOrderFeeUsd.selector;
    perpMarketHarnessSelectors[6] = PerpMarketHarness.exposed_getNextFundingFeePerUnit.selector;
    perpMarketHarnessSelectors[7] = PerpMarketHarness.exposed_getPendingFundingFeePerUnit.selector;
    perpMarketHarnessSelectors[8] = PerpMarketHarness.exposed_getProportionalElapsedSinceLastFunding.selector;
    perpMarketHarnessSelectors[9] = PerpMarketHarness.exposed_checkOpenInterestLimits.selector;
    perpMarketHarnessSelectors[10] = PerpMarketHarness.exposed_checkTradeSize.selector;
    perpMarketHarnessSelectors[11] = PerpMarketHarness.exposed_updateFunding.selector;
    perpMarketHarnessSelectors[12] = PerpMarketHarness.exposed_updateOpenInterest.selector;
    perpMarketHarnessSelectors[13] = PerpMarketHarness.exposed_create.selector;

    bytes4[] memory positionHarnessSelectors = new bytes4[](8);
    positionHarnessSelectors[0] = PositionHarness.exposed_Position_load.selector;
    positionHarnessSelectors[1] = PositionHarness.exposed_getState.selector;
    positionHarnessSelectors[2] = PositionHarness.exposed_update.selector;
    positionHarnessSelectors[3] = PositionHarness.exposed_clear.selector;
    positionHarnessSelectors[4] = PositionHarness.exposed_getAccruedFunding.selector;
    positionHarnessSelectors[5] = PositionHarness.exposed_getMarginRequirements.selector;
    positionHarnessSelectors[6] = PositionHarness.exposed_getNotionalValue.selector;
    positionHarnessSelectors[7] = PositionHarness.exposed_getUnrealizedPnl.selector;

    bytes4[] memory settlementConfigurationHarnessSelectors = new bytes4[](6);
    settlementConfigurationHarnessSelectors[0] =
        SettlementConfigurationHarness.exposed_SettlementConfiguration_load.selector;
    settlementConfigurationHarnessSelectors[1] =
        SettlementConfigurationHarness.exposed_checkIsSettlementEnabled.selector;
    settlementConfigurationHarnessSelectors[2] =
        SettlementConfigurationHarness.exposed_requireDataStreamsReportIsVaid.selector;
    settlementConfigurationHarnessSelectors[3] = SettlementConfigurationHarness.exposed_update.selector;
    settlementConfigurationHarnessSelectors[4] = SettlementConfigurationHarness.exposed_verifyOffchainPrice.selector;
    settlementConfigurationHarnessSelectors[5] =
        SettlementConfigurationHarness.exposed_verifyDataStreamsReport.selector;

    bytes4[] memory tradingAccountHarnessSelectors = new bytes4[](22);
    tradingAccountHarnessSelectors[0] = TradingAccountHarness.exposed_TradingAccount_loadExisting.selector;
    tradingAccountHarnessSelectors[1] = TradingAccountHarness.exposed_loadExistingAccountAndVerifySender.selector;
    tradingAccountHarnessSelectors[2] = TradingAccountHarness.exposed_validatePositionsLimit.selector;
    tradingAccountHarnessSelectors[3] = TradingAccountHarness.exposed_validateMarginRequirements.selector;
    tradingAccountHarnessSelectors[4] = TradingAccountHarness.exposed_getMarginCollateralBalance.selector;
    tradingAccountHarnessSelectors[5] = TradingAccountHarness.exposed_getEquityUsd.selector;
    tradingAccountHarnessSelectors[6] = TradingAccountHarness.exposed_getMarginBalanceUsd.selector;
    tradingAccountHarnessSelectors[7] =
        TradingAccountHarness.exposed_getAccountMarginRequirementUsdAndUnrealizedPnlUsd.selector;
    tradingAccountHarnessSelectors[8] = TradingAccountHarness.exposed_getAccontUnrealizedPnlUsd.selector;
    tradingAccountHarnessSelectors[9] = TradingAccountHarness.exposed_verifySender.selector;
    tradingAccountHarnessSelectors[10] = TradingAccountHarness.exposed_isLiquidatable.selector;
    tradingAccountHarnessSelectors[11] = TradingAccountHarness.exposed_create.selector;
    tradingAccountHarnessSelectors[12] = TradingAccountHarness.exposed_deposit.selector;
    tradingAccountHarnessSelectors[13] = TradingAccountHarness.exposed_withdraw.selector;
    tradingAccountHarnessSelectors[14] = TradingAccountHarness.exposed_withdrawMarginUsd.selector;
    tradingAccountHarnessSelectors[15] = TradingAccountHarness.exposed_deductAccountMargin.selector;
    tradingAccountHarnessSelectors[16] = TradingAccountHarness.exposed_updateActiveMarkets.selector;
    tradingAccountHarnessSelectors[17] = TradingAccountHarness.workaround_getActiveMarketId.selector;
    tradingAccountHarnessSelectors[18] = TradingAccountHarness.workaround_getActiveMarketsIdsLength.selector;
    tradingAccountHarnessSelectors[19] = TradingAccountHarness.workaround_getNonce.selector;
    tradingAccountHarnessSelectors[20] = TradingAccountHarness.workaround_hasOffchainOrderBeenFilled.selector;
    tradingAccountHarnessSelectors[21] =
        TradingAccountHarness.workaround_getIfMarginCollateralBalanceX18ContainsTheCollateral.selector;

    selectors[0] = globalConfigurationHarnessSelectors;
    selectors[1] = marginCollateralConfigurationHarnessSelectors;
    selectors[2] = marketConfigurationHarnessSelectors;
    selectors[3] = marketOrderHarnessSelectors;
    selectors[4] = perpMarketHarnessSelectors;
    selectors[5] = positionHarnessSelectors;
    selectors[6] = settlementConfigurationHarnessSelectors;
    selectors[7] = tradingAccountHarnessSelectors;

    return selectors;
}
