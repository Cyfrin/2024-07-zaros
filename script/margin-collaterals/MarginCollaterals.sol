// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Margin Collaterals
import { Usdz } from "script/margin-collaterals/Usdz.sol";
import { Usdc } from "script/margin-collaterals/Usdc.sol";
import { WEth } from "script/margin-collaterals/WEth.sol";
import { WBtc } from "script/margin-collaterals/WBtc.sol";
import { WstEth } from "script/margin-collaterals/WstEth.sol";
import { WeEth } from "script/margin-collaterals/WeEth.sol";

// Zaros dependencies
import { IPerpsEngine } from "@zaros/perpetuals/PerpsEngine.sol";
import { MockERC20 } from "test/mocks/MockERC20.sol";
import { MockUSDToken } from "test/mocks/MockUSDToken.sol";
import { MockPriceFeed } from "test/mocks/MockPriceFeed.sol";

abstract contract MarginCollaterals is Usdz, Usdc, WEth, WBtc, WstEth, WeEth {
    struct MarginCollateral {
        string name;
        string symbol;
        uint256 marginCollateralId;
        uint128 depositCap;
        uint120 loanToValue;
        uint256 minDepositMargin;
        uint256 mockUsdPrice;
        address marginCollateralAddress;
        address priceFeed;
        uint256 liquidationPriority;
        uint8 tokenDecimals;
        uint32 priceFeedHearbeatSeconds;
    }

    mapping(uint256 marginCollateralId => MarginCollateral marginCollateral) internal marginCollaterals;

    function setupMarginCollaterals() internal {
        MarginCollateral memory usdcConfig = MarginCollateral({
            name: USDC_NAME,
            symbol: USDC_SYMBOL,
            marginCollateralId: USDC_MARGIN_COLLATERAL_ID,
            depositCap: USDC_DEPOSIT_CAP_X18.intoUint128(),
            loanToValue: USDC_LOAN_TO_VALUE,
            minDepositMargin: USDC_MIN_DEPOSIT_MARGIN,
            mockUsdPrice: MOCK_USDC_USD_PRICE,
            marginCollateralAddress: USDC_ADDRESS,
            priceFeed: USDC_PRICE_FEED,
            liquidationPriority: USDC_LIQUIDATION_PRIORITY,
            tokenDecimals: USDC_DECIMALS,
            priceFeedHearbeatSeconds: USDC_PRICE_FEED_HEARBEAT_SECONDS
        });
        marginCollaterals[USDC_MARGIN_COLLATERAL_ID] = usdcConfig;

        MarginCollateral memory usdzConfig = MarginCollateral({
            name: USDZ_NAME,
            symbol: USDZ_SYMBOL,
            marginCollateralId: USDZ_MARGIN_COLLATERAL_ID,
            depositCap: USDZ_DEPOSIT_CAP_X18.intoUint128(),
            loanToValue: USDZ_LOAN_TO_VALUE,
            minDepositMargin: USDZ_MIN_DEPOSIT_MARGIN,
            mockUsdPrice: MOCK_USDZ_USD_PRICE,
            marginCollateralAddress: USDZ_ADDRESS,
            priceFeed: USDZ_PRICE_FEED,
            liquidationPriority: USDZ_LIQUIDATION_PRIORITY,
            tokenDecimals: USDZ_DECIMALS,
            priceFeedHearbeatSeconds: USDZ_PRICE_FEED_HEARBEAT_SECONDS
        });
        marginCollaterals[USDZ_MARGIN_COLLATERAL_ID] = usdzConfig;

        MarginCollateral memory wEth = MarginCollateral({
            name: WETH_NAME,
            symbol: WETH_SYMBOL,
            marginCollateralId: WETH_MARGIN_COLLATERAL_ID,
            depositCap: WETH_DEPOSIT_CAP_X18.intoUint128(),
            loanToValue: WETH_LOAN_TO_VALUE,
            minDepositMargin: WETH_MIN_DEPOSIT_MARGIN,
            mockUsdPrice: MOCK_WETH_USD_PRICE,
            marginCollateralAddress: WETH_ADDRESS,
            priceFeed: WETH_PRICE_FEED,
            liquidationPriority: WETH_LIQUIDATION_PRIORITY,
            tokenDecimals: WETH_DECIMALS,
            priceFeedHearbeatSeconds: WETH_PRICE_FEED_HEARBEAT_SECONDS
        });
        marginCollaterals[WETH_MARGIN_COLLATERAL_ID] = wEth;

        MarginCollateral memory weEth = MarginCollateral({
            name: WEETH_NAME,
            symbol: WEETH_SYMBOL,
            marginCollateralId: WEETH_MARGIN_COLLATERAL_ID,
            depositCap: WEETH_DEPOSIT_CAP_X18.intoUint128(),
            loanToValue: WEETH_LOAN_TO_VALUE,
            minDepositMargin: WEETH_MIN_DEPOSIT_MARGIN,
            mockUsdPrice: MOCK_WEETH_USD_PRICE,
            marginCollateralAddress: WEETH_ADDRESS,
            priceFeed: WEETH_PRICE_FEED,
            liquidationPriority: WEETH_LIQUIDATION_PRIORITY,
            tokenDecimals: WEETH_DECIMALS,
            priceFeedHearbeatSeconds: WEETH_PRICE_FEED_HEARBEAT_SECONDS
        });
        marginCollaterals[WEETH_MARGIN_COLLATERAL_ID] = weEth;

        MarginCollateral memory wBtc = MarginCollateral({
            name: WBTC_NAME,
            symbol: WBTC_SYMBOL,
            marginCollateralId: WBTC_MARGIN_COLLATERAL_ID,
            depositCap: WBTC_DEPOSIT_CAP_X18.intoUint128(),
            loanToValue: WBTC_LOAN_TO_VALUE,
            minDepositMargin: WBTC_MIN_DEPOSIT_MARGIN,
            mockUsdPrice: MOCK_WBTC_USD_PRICE,
            marginCollateralAddress: WBTC_ADDRESS,
            priceFeed: WBTC_PRICE_FEED,
            liquidationPriority: WBTC_LIQUIDATION_PRIORITY,
            tokenDecimals: WBTC_DECIMALS,
            priceFeedHearbeatSeconds: WBTC_PRICE_FEED_HEARBEAT_SECONDS
        });
        marginCollaterals[WBTC_MARGIN_COLLATERAL_ID] = wBtc;

        MarginCollateral memory wstEth = MarginCollateral({
            name: WSTETH_NAME,
            symbol: WSTETH_SYMBOL,
            marginCollateralId: WSTETH_MARGIN_COLLATERAL_ID,
            depositCap: WSTETH_DEPOSIT_CAP_X18.intoUint128(),
            loanToValue: WSTETH_LOAN_TO_VALUE,
            minDepositMargin: WSTETH_MIN_DEPOSIT_MARGIN,
            mockUsdPrice: MOCK_WSTETH_USD_PRICE,
            marginCollateralAddress: WSTETH_ADDRESS,
            priceFeed: WSTETH_PRICE_FEED,
            liquidationPriority: WSTETH_LIQUIDATION_PRIORITY,
            tokenDecimals: WSTETH_DECIMALS,
            priceFeedHearbeatSeconds: WSTETH_PRICE_FEED_HEARBEAT_SECONDS
        });
        marginCollaterals[WSTETH_MARGIN_COLLATERAL_ID] = wstEth;
    }

    function getFilteredMarginCollateralsConfig(uint256[2] memory marginCollateralIdsRange)
        internal
        view
        returns (MarginCollateral[] memory)
    {
        uint256 initialMarginCollateralId = marginCollateralIdsRange[0];
        uint256 finalMarginCollateralId = marginCollateralIdsRange[1];
        uint256 filteredMarketsLength = finalMarginCollateralId - initialMarginCollateralId + 1;

        MarginCollateral[] memory filteredMarginCollateralsConfig = new MarginCollateral[](filteredMarketsLength);

        uint256 nextMarginCollateralId = initialMarginCollateralId;
        for (uint256 i; i < filteredMarketsLength; i++) {
            filteredMarginCollateralsConfig[i] = marginCollaterals[nextMarginCollateralId];
            nextMarginCollateralId++;
        }

        return filteredMarginCollateralsConfig;
    }

    function configureMarginCollaterals(
        IPerpsEngine perpsEngine,
        uint256[2] memory marginCollateralIdsRange,
        bool isTestnet,
        address owner
    )
        internal
    {
        setupMarginCollaterals();

        MarginCollateral[] memory filteredMarginCollateralsConfig =
            getFilteredMarginCollateralsConfig(marginCollateralIdsRange);

        address[] memory collateralLiquidationPriority = new address[](filteredMarginCollateralsConfig.length);

        for (uint256 i; i < filteredMarginCollateralsConfig.length; i++) {
            uint256 indexLiquidationPriority = filteredMarginCollateralsConfig[i].liquidationPriority - 1;

            address marginCollateralAddress;
            address priceFeed;
            address mockERC20;

            if (isTestnet) {
                if (filteredMarginCollateralsConfig[i].marginCollateralId == USDZ_MARGIN_COLLATERAL_ID) {
                    mockERC20 = address(new MockUSDToken({ owner: owner, deployerBalance: 100_000_000e18 }));
                } else {
                    mockERC20 = address(
                        new MockERC20({
                            name: filteredMarginCollateralsConfig[i].name,
                            symbol: filteredMarginCollateralsConfig[i].symbol,
                            decimals_: filteredMarginCollateralsConfig[i].tokenDecimals,
                            deployerBalance: filteredMarginCollateralsConfig[i].minDepositMargin
                        })
                    );
                }

                marginCollateralAddress = address(mockERC20);

                MockPriceFeed mockPriceFeed = new MockPriceFeed(
                    filteredMarginCollateralsConfig[i].tokenDecimals,
                    int256(filteredMarginCollateralsConfig[i].mockUsdPrice)
                );

                priceFeed = address(mockPriceFeed);

                marginCollaterals[filteredMarginCollateralsConfig[i].marginCollateralId].marginCollateralAddress =
                    marginCollateralAddress;
                filteredMarginCollateralsConfig[i].marginCollateralAddress = marginCollateralAddress;

                marginCollaterals[filteredMarginCollateralsConfig[i].marginCollateralId].priceFeed = priceFeed;
                filteredMarginCollateralsConfig[i].priceFeed = priceFeed;
            }

            collateralLiquidationPriority[indexLiquidationPriority] =
                filteredMarginCollateralsConfig[i].marginCollateralAddress;

            perpsEngine.configureMarginCollateral(
                filteredMarginCollateralsConfig[i].marginCollateralAddress,
                filteredMarginCollateralsConfig[i].depositCap,
                filteredMarginCollateralsConfig[i].loanToValue,
                filteredMarginCollateralsConfig[i].priceFeed,
                filteredMarginCollateralsConfig[i].priceFeedHearbeatSeconds
            );
        }

        perpsEngine.configureCollateralLiquidationPriority(collateralLiquidationPriority);
    }
}
