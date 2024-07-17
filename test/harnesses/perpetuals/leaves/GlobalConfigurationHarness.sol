// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { GlobalConfiguration } from "@zaros/perpetuals/leaves/GlobalConfiguration.sol";

// Open Zeppelin dependencies
import { EnumerableSet } from "@openzeppelin/utils/structs/EnumerableSet.sol";

contract GlobalConfigurationHarness {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    function workaround_getSequencerUptimeFeedByChainId(uint256 chainId) external view returns (address) {
        GlobalConfiguration.Data storage self = GlobalConfiguration.load();

        return self.sequencerUptimeFeedByChainId[chainId];
    }

    function workaround_getCollateralLiquidationPriority() external view returns (address[] memory) {
        GlobalConfiguration.Data storage self = GlobalConfiguration.load();
        uint256 length = self.collateralLiquidationPriority.length();

        address[] memory collateralLiquidationPriority = new address[](length);

        for (uint256 i; i < length; i++) {
            collateralLiquidationPriority[i] = self.collateralLiquidationPriority.at(i);
        }

        return collateralLiquidationPriority;
    }

    function workaround_getTradingAccountToken() external view returns (address) {
        GlobalConfiguration.Data storage self = GlobalConfiguration.load();

        return self.tradingAccountToken;
    }

    function workaround_getUsdToken() external view returns (address) {
        GlobalConfiguration.Data storage self = GlobalConfiguration.load();

        return self.usdToken;
    }

    function workaround_getAccountIdWithActivePositions(uint128 index) external view returns (uint128) {
        GlobalConfiguration.Data storage self = GlobalConfiguration.load();

        return uint128(self.accountsIdsWithActivePositions.at(index));
    }

    function workaround_getAccountsIdsWithActivePositionsLength() external view returns (uint256) {
        GlobalConfiguration.Data storage self = GlobalConfiguration.load();

        return self.accountsIdsWithActivePositions.length();
    }

    function exposed_checkMarketIsEnabled(uint128 marketId) external view {
        GlobalConfiguration.Data storage self = GlobalConfiguration.load();
        GlobalConfiguration.checkMarketIsEnabled(self, marketId);
    }

    function exposed_addMarket(uint128 marketId) external {
        GlobalConfiguration.Data storage self = GlobalConfiguration.load();
        GlobalConfiguration.addMarket(self, marketId);
    }

    function exposed_removeMarket(uint128 marketId) external {
        GlobalConfiguration.Data storage self = GlobalConfiguration.load();
        GlobalConfiguration.removeMarket(self, marketId);
    }

    function exposed_configureCollateralLiquidationPriority(address[] memory collateralTokens) external {
        GlobalConfiguration.Data storage self = GlobalConfiguration.load();
        GlobalConfiguration.configureCollateralLiquidationPriority(self, collateralTokens);
    }

    function exposed_removeCollateralFromLiquidationPriority(address collateralToken) external {
        GlobalConfiguration.Data storage self = GlobalConfiguration.load();
        GlobalConfiguration.removeCollateralFromLiquidationPriority(self, collateralToken);
    }
}
