// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { Base_Test } from "test/Base.t.sol";
import { IPerpsEngine } from "@zaros/perpetuals/PerpsEngine.sol";
import { MarketOrderKeeper } from "@zaros/external/chainlink/keepers/market-order/MarketOrderKeeper.sol";

// Open Zeppelin dependencies
import { ERC1967Proxy } from "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

contract MarketOrderKeeper_Initialize_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();

        createPerpMarkets();

        changePrank({ msgSender: users.naruto.account });
    }

    modifier givenInitializeContractWithSomeWrongInformation() {
        _;
    }

    function testFuzz_RevertWhen_AddressOfPerpsEngineIsZero(uint256 marketId)
        external
        givenInitializeContractWithSomeWrongInformation
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);

        address marketOrderKeeperImplementation = address(new MarketOrderKeeper());

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "perpsEngine") });

        new ERC1967Proxy(
            marketOrderKeeperImplementation,
            abi.encodeWithSelector(
                MarketOrderKeeper.initialize.selector,
                users.owner.account,
                IPerpsEngine(address(0)),
                fuzzMarketConfig.marketId,
                fuzzMarketConfig.streamIdString
            )
        );
    }

    function test_RevertWhen_MarketIdIsZero() external givenInitializeContractWithSomeWrongInformation {
        address marketOrderKeeperImplementation = address(new MarketOrderKeeper());

        uint128 marketId = 0;
        string memory streamIdString = "0x";

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "marketId") });

        new ERC1967Proxy(
            marketOrderKeeperImplementation,
            abi.encodeWithSelector(
                MarketOrderKeeper.initialize.selector, users.owner.account, perpsEngine, marketId, streamIdString
            )
        );
    }

    function testFuzz_RevertWhen_StreamIdIsZero(uint256 marketId)
        external
        givenInitializeContractWithSomeWrongInformation
    {
        MarketConfig memory fuzzMarketConfig = getFuzzMarketConfig(marketId);
        address marketOrderKeeperImplementation = address(new MarketOrderKeeper());

        string memory streamIdString = "";

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "streamId") });

        new ERC1967Proxy(
            marketOrderKeeperImplementation,
            abi.encodeWithSelector(
                MarketOrderKeeper.initialize.selector,
                users.owner.account,
                perpsEngine,
                fuzzMarketConfig.marketId,
                streamIdString
            )
        );
    }
}
