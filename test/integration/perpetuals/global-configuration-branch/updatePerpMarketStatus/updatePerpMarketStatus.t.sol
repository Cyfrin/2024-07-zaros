// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { Base_Test } from "test/Base.t.sol";
import { GlobalConfigurationBranch } from "@zaros/perpetuals/branches/GlobalConfigurationBranch.sol";

contract UpdatePerpMarketStatus_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function testFuzz_RevertGiven_PerpMarketIsNotInitialized() external {
        uint128 marketIdNotInitialized = uint128(FINAL_MARKET_ID) + 1;

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.PerpMarketNotInitialized.selector, marketIdNotInitialized)
        });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.updatePerpMarketStatus(marketIdNotInitialized, true);
    }

    modifier givenPerpMarketIsInitialized() {
        _;
    }

    function testFuzz_RevertWhen_PerpMarketIsEnabledAndNewEnableStatusIsTrue(uint256 marketId)
        external
        givenPerpMarketIsInitialized
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.PerpMarketAlreadyEnabled.selector, fuzzMarketConfig.marketId)
        });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.updatePerpMarketStatus(fuzzMarketConfig.marketId, true);
    }

    function testFuzz_WhenPerpMarketIsEnabledAndNewEnableStatusIsFalse(uint256 marketId)
        external
        givenPerpMarketIsInitialized
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        changePrank({ msgSender: users.owner.account });

        // it should emit {LogDisablePerpMarket} event
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit GlobalConfigurationBranch.LogDisablePerpMarket(users.owner.account, fuzzMarketConfig.marketId);

        // it should remove market
        perpsEngine.updatePerpMarketStatus(fuzzMarketConfig.marketId, false);
    }

    function testFuzz_WhenPerpMarketIsNotEnabledAndNewEnableStatusIsTrue(uint256 marketId)
        external
        givenPerpMarketIsInitialized
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        changePrank({ msgSender: users.owner.account });

        perpsEngine.updatePerpMarketStatus(fuzzMarketConfig.marketId, false);

        // it should emit {LogEnablePerpMarket} event
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit GlobalConfigurationBranch.LogEnablePerpMarket(users.owner.account, fuzzMarketConfig.marketId);

        // it should add market
        perpsEngine.updatePerpMarketStatus(fuzzMarketConfig.marketId, true);
    }

    function testFuzz_RevertWhen_PerpMarketIsNotEnabledAndNewEnableStatusIsFalse(uint256 marketId)
        external
        givenPerpMarketIsInitialized
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        changePrank({ msgSender: users.owner.account });

        perpsEngine.updatePerpMarketStatus(fuzzMarketConfig.marketId, false);

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.PerpMarketAlreadyDisabled.selector, fuzzMarketConfig.marketId)
        });

        perpsEngine.updatePerpMarketStatus(fuzzMarketConfig.marketId, false);
    }
}
