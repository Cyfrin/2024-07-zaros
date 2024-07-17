// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { Base_Test } from "test/Base.t.sol";
import { SettlementConfiguration } from "@zaros/perpetuals/leaves/SettlementConfiguration.sol";
import { OrderBranch } from "@zaros/perpetuals/branches/OrderBranch.sol";
import { MockPriceFeed } from "test/mocks/MockPriceFeed.sol";

// PRB Math dependencies
import { ud60x18, UD60x18 } from "@prb-math/UD60x18.sol";
import { SD59x18 } from "@prb-math/SD59x18.sol";

contract GetAccountEquityUsd_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function testFuzz_RevertGiven_TheTradingAccountDoesNotExist(uint128 randomTradingAccountId) external {
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.AccountNotFound.selector, randomTradingAccountId, users.naruto.account
            )
        });

        // it should revert
        perpsEngine.getAccountEquityUsd(randomTradingAccountId);
    }

    modifier givenTheTradingAccountExists() {
        _;
    }

    function test_GivenTheresNoOpenPosition(
        uint256 usdcMarginValueUsd,
        uint256 wstEthMarginValueUsd
    )
        external
        givenTheTradingAccountExists
    {
        usdcMarginValueUsd = bound({
            x: usdcMarginValueUsd,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });
        deal({ token: address(usdc), to: users.naruto.account, give: usdcMarginValueUsd });

        wstEthMarginValueUsd = bound({
            x: wstEthMarginValueUsd,
            min: WSTETH_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(wstEth), WSTETH_DEPOSIT_CAP_X18)
        });
        deal({ token: address(wstEth), to: users.naruto.account, give: wstEthMarginValueUsd });

        uint128 tradingAccountId = createAccountAndDeposit(usdcMarginValueUsd, address(usdc));
        perpsEngine.depositMargin(tradingAccountId, address(wstEth), wstEthMarginValueUsd);

        UD60x18 usdcEquityUsd = getPrice(MockPriceFeed(marginCollaterals[USDC_MARGIN_COLLATERAL_ID].priceFeed)).mul(
            convertTokenAmountToUd60x18(address(usdc), usdcMarginValueUsd)
        );

        UD60x18 wstEthEquityUsd = getPrice(MockPriceFeed(marginCollaterals[WSTETH_MARGIN_COLLATERAL_ID].priceFeed))
            .mul(convertTokenAmountToUd60x18(address(wstEth), wstEthMarginValueUsd));

        UD60x18 marginCollateralValue = usdcEquityUsd.add(wstEthEquityUsd);

        // it should return the account equity usd
        SD59x18 equityUsd = perpsEngine.getAccountEquityUsd(tradingAccountId);
        assertEq(
            marginCollateralValue.intoUint256(), equityUsd.intoUint256(), "Account equity usd is not the expected"
        );
    }

    function test_GivenTheresAnPositionCreated(
        uint256 initialMarginRate,
        uint256 wstEthmarginValueUsd,
        uint256 weEthmarginValueUsd,
        bool isLong,
        uint256 marketId
    )
        external
        givenTheTradingAccountExists
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        initialMarginRate =
            bound({ x: initialMarginRate, min: fuzzMarketConfig.marginRequirements, max: MAX_MARGIN_REQUIREMENTS });

        wstEthmarginValueUsd = bound({
            x: wstEthmarginValueUsd,
            min: WSTETH_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(wstEth), WSTETH_DEPOSIT_CAP_X18)
        });
        deal({ token: address(wstEth), to: users.naruto.account, give: wstEthmarginValueUsd });

        weEthmarginValueUsd = bound({
            x: weEthmarginValueUsd,
            min: 1,
            max: convertUd60x18ToTokenAmount(address(weEth), WEETH_DEPOSIT_CAP_X18)
        });
        deal({ token: address(weEth), to: users.naruto.account, give: weEthmarginValueUsd });

        uint128 tradingAccountId = createAccountAndDeposit(wstEthmarginValueUsd, address(wstEth));
        perpsEngine.depositMargin(tradingAccountId, address(weEth), weEthmarginValueUsd);

        int128 sizeDelta = fuzzOrderSizeDelta(
            FuzzOrderSizeDeltaParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                settlementConfigurationId: SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
                initialMarginRate: ud60x18(initialMarginRate),
                marginValueUsd: ud60x18(wstEthmarginValueUsd).add(ud60x18(weEthmarginValueUsd)),
                maxSkew: ud60x18(fuzzMarketConfig.maxSkew),
                minTradeSize: ud60x18(fuzzMarketConfig.minTradeSize),
                price: ud60x18(fuzzMarketConfig.mockUsdPrice),
                isLong: isLong,
                shouldDiscountFees: true
            })
        );

        perpsEngine.createMarketOrder(
            OrderBranch.CreateMarketOrderParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                sizeDelta: sizeDelta
            })
        );

        bytes memory mockSignedReport =
            getMockedSignedReport(fuzzMarketConfig.streamId, fuzzMarketConfig.mockUsdPrice);

        address marketOrderKeeper = marketOrderKeepers[fuzzMarketConfig.marketId];

        changePrank({ msgSender: marketOrderKeeper });
        perpsEngine.fillMarketOrder(tradingAccountId, fuzzMarketConfig.marketId, mockSignedReport);

        SD59x18 accountTotalUnrealizedPnl = perpsEngine.getAccountTotalUnrealizedPnl(tradingAccountId);

        UD60x18 marginCollateralValue = getPrice(
            MockPriceFeed(marginCollaterals[WSTETH_MARGIN_COLLATERAL_ID].priceFeed)
        ).mul(ud60x18(wstEthmarginValueUsd)).add(
            getPrice(MockPriceFeed(marginCollaterals[WEETH_MARGIN_COLLATERAL_ID].priceFeed)).mul(
                ud60x18(weEthmarginValueUsd)
            )
        );

        // it should return the account equity usd
        SD59x18 equityUsd = perpsEngine.getAccountEquityUsd(tradingAccountId);

        SD59x18 expectedEquityUsd = marginCollateralValue.intoSD59x18().add(accountTotalUnrealizedPnl);

        assertAlmostEq(
            expectedEquityUsd.intoUint256(), equityUsd.intoUint256(), 6e23, "Account equity usd is not the expected"
        );
    }
}
