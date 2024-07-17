// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { MarketOrderKeeper } from "@zaros/external/chainlink/keepers/market-order/MarketOrderKeeper.sol";

contract MarketOrderKeeper_GetConfig_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();

        createPerpMarkets();

        changePrank({ msgSender: users.naruto.account });
    }

    modifier givenInitializeContract() {
        _;
    }

    function testFuzz_WhenCallGetConfigFunction(uint256 marketId) external givenInitializeContract {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);
        address marketOrderKeeperImplementation = address(new MarketOrderKeeper());

        address marketOrderKeeper = deployMarketOrderKeeper(
            fuzzMarketConfig.marketId, users.owner.account, perpsEngine, marketOrderKeeperImplementation
        );

        (address keeperOwner,, address perpsEngine, uint256 marketIdConfig) =
            MarketOrderKeeper(marketOrderKeeper).getConfig();

        // it should return keeper owner
        assertEq(users.owner.account, keeperOwner, "keeper owner is not correct");

        // it should return address of perps engine
        assertEq(address(perpsEngine), perpsEngine, "perps engine is not correct");

        // it should return market id
        assertEq(fuzzMarketConfig.marketId, marketIdConfig, "market id is not correct");
    }
}
