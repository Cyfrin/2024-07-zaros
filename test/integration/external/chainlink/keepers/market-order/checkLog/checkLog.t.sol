// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { OrderBranch } from "@zaros/perpetuals/branches/OrderBranch.sol";
import { SettlementConfiguration } from "@zaros/perpetuals/leaves/SettlementConfiguration.sol";
import { Log as AutomationLog } from "@zaros/external/chainlink/interfaces/ILogAutomation.sol";
import { MarketOrder } from "@zaros/perpetuals/leaves/MarketOrder.sol";
import { MarketOrderKeeper } from "@zaros/external/chainlink/keepers/market-order/MarketOrderKeeper.sol";
import { IStreamsLookupCompatible } from "@zaros/external/chainlink/interfaces/IStreamsLookupCompatible.sol";

// PRB Math dependencies
import { ud60x18 } from "@prb-math/UD60x18.sol";

contract MarketOrderKeeper_CheckLog_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();

        createPerpMarkets();

        changePrank({ msgSender: users.naruto.account });
    }

    function test_RevertWhen_CheckLogIsCalled(
        uint256 initialMarginRate,
        uint256 marginValueUsd,
        bool isLong,
        uint256 marketId
    )
        external
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        initialMarginRate =
            bound({ x: initialMarginRate, min: fuzzMarketConfig.marginRequirements, max: MAX_MARGIN_REQUIREMENTS });
        marginValueUsd = bound({
            x: marginValueUsd,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });

        deal({ token: address(usdc), to: users.naruto.account, give: marginValueUsd });

        uint128 tradingAccountId = createAccountAndDeposit(marginValueUsd, address(usdc));
        int128 sizeDelta = fuzzOrderSizeDelta(
            FuzzOrderSizeDeltaParams({
                tradingAccountId: tradingAccountId,
                marketId: fuzzMarketConfig.marketId,
                settlementConfigurationId: SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID,
                initialMarginRate: ud60x18(initialMarginRate),
                marginValueUsd: ud60x18(marginValueUsd),
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

        // it should return the active market order
        MarketOrder.Data memory marketOrder = perpsEngine.getActiveMarketOrder(tradingAccountId);

        bytes memory extraData = abi.encode("extraData");

        bytes32[] memory topics = new bytes32[](4);
        topics[0] = keccak256(abi.encode("Log(address,uint128,uint256)"));
        topics[1] = keccak256(abi.encode(address(perpsEngine)));
        topics[2] = bytes32(uint256(tradingAccountId));
        topics[3] = keccak256(abi.encode(fuzzMarketConfig.marketId));

        AutomationLog memory mockedLog = AutomationLog({
            index: 0,
            timestamp: 0,
            txHash: 0,
            blockNumber: 0,
            blockHash: 0,
            source: address(0),
            topics: topics,
            data: abi.encode(marketOrder)
        });

        address marketOrderKeeper = marketOrderKeepers[fuzzMarketConfig.marketId];

        string[] memory streams = new string[](1);
        streams[0] = fuzzMarketConfig.streamIdString;

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                IStreamsLookupCompatible.StreamsLookup.selector,
                "feedIDs",
                streams,
                "timestamp",
                marketOrder.timestamp,
                abi.encode(tradingAccountId)
            )
        });

        MarketOrderKeeper(marketOrderKeeper).checkLog(mockedLog, extraData);
    }
}
