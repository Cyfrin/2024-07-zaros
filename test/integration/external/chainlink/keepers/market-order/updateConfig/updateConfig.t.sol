// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { Base_Test } from "test/Base.t.sol";
import { IPerpsEngine } from "@zaros/perpetuals/PerpsEngine.sol";
import { Markets } from "script/markets/Markets.sol";
import { MarketOrder } from "@zaros/perpetuals/leaves/MarketOrder.sol";

import { MarketOrderKeeper } from "@zaros/external/chainlink/keepers/market-order/MarketOrderKeeper.sol";

contract MarketOrderKeeper_UpdateConfig_Integration_Test is Base_Test {
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

    modifier givenCallUpdateConfigFunction() {
        _;
    }

    function testFuzz_GivenCallUpdateConfigFunction(uint256 marketId)
        external
        givenInitializeContract
        givenCallUpdateConfigFunction
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);
        address marketOrderKeeperImplementation = address(new MarketOrderKeeper());

        address marketOrderKeeper = deployMarketOrderKeeper(
            fuzzMarketConfig.marketId, users.owner.account, perpsEngine, marketOrderKeeperImplementation
        );

        IPerpsEngine newPersEngine = IPerpsEngine(address(0x123));
        uint128 newMarketId = uint128(FINAL_MARKET_ID + 1);
        string memory newStreamId = "0x";

        changePrank({ msgSender: users.owner.account });

        // it should update the config
        MarketOrderKeeper(marketOrderKeeper).updateConfig(newPersEngine, newMarketId, newStreamId);

        (address keeperOwner,, address perpsEngine, uint256 marketIdConfig) =
            MarketOrderKeeper(marketOrderKeeper).getConfig();

        assertEq(users.owner.account, keeperOwner, "keeper owner is not correct");
        assertEq(address(newPersEngine), perpsEngine, "perps engine is not correct");
        assertEq(newMarketId, marketIdConfig, "market id is not correct");
    }

    function testFuzz_WhenAddressOfPerpsEngineIsZero(uint256 marketId)
        external
        givenInitializeContract
        givenCallUpdateConfigFunction
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);
        address marketOrderKeeperImplementation = address(new MarketOrderKeeper());

        address marketOrderKeeper = deployMarketOrderKeeper(
            fuzzMarketConfig.marketId, users.owner.account, perpsEngine, marketOrderKeeperImplementation
        );

        IPerpsEngine newPersEngine = IPerpsEngine(address(0));
        uint128 newMarketId = uint128(FINAL_MARKET_ID + 1);
        string memory newStreamId = "0x";

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "perpsEngine") });

        changePrank({ msgSender: users.owner.account });
        MarketOrderKeeper(marketOrderKeeper).updateConfig(newPersEngine, newMarketId, newStreamId);
    }

    function testFuzz_WhenMarketIdIsZero(uint256 marketId)
        external
        givenInitializeContract
        givenCallUpdateConfigFunction
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);
        address marketOrderKeeperImplementation = address(new MarketOrderKeeper());

        address marketOrderKeeper = deployMarketOrderKeeper(
            fuzzMarketConfig.marketId, users.owner.account, perpsEngine, marketOrderKeeperImplementation
        );

        IPerpsEngine newPersEngine = IPerpsEngine(address(0x123));
        uint128 newMarketId = 0;
        string memory newStreamId = "0x";

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "marketId") });

        changePrank({ msgSender: users.owner.account });
        MarketOrderKeeper(marketOrderKeeper).updateConfig(newPersEngine, newMarketId, newStreamId);
    }

    function testFuzz_WhenStreamIdIsZero(uint256 marketId)
        external
        givenInitializeContract
        givenCallUpdateConfigFunction
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);
        address marketOrderKeeperImplementation = address(new MarketOrderKeeper());

        address marketOrderKeeper = deployMarketOrderKeeper(
            fuzzMarketConfig.marketId, users.owner.account, perpsEngine, marketOrderKeeperImplementation
        );

        IPerpsEngine newPersEngine = IPerpsEngine(address(0x123));
        uint128 newMarketId = uint128(FINAL_MARKET_ID + 1);
        string memory newStreamId = "";

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "streamId") });

        changePrank({ msgSender: users.owner.account });
        MarketOrderKeeper(marketOrderKeeper).updateConfig(newPersEngine, newMarketId, newStreamId);
    }
}
