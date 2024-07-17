// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Constants } from "@zaros/utils/Constants.sol";
import { Errors } from "@zaros/utils/Errors.sol";
import { Base_Test } from "test/Base.t.sol";
import { GlobalConfigurationBranch } from "@zaros/perpetuals/branches/GlobalConfigurationBranch.sol";
import { MockERC20 } from "test/mocks/MockERC20.sol";
import { MockERC20WithNoDecimals } from "test/mocks/MockERC20WithNoDecimals.sol";
import { MockERC20WithZeroDecimals } from "test/mocks/MockERC20WithZeroDecimals.sol";

// OpenZeppelin Upgradeable dependencies
import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";

contract ConfigureMarginCollateral_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
        changePrank({ msgSender: users.owner.account });
        configureSystemParameters();
        createPerpMarkets();
        changePrank({ msgSender: users.naruto.account });
    }

    function testFuzz_RevertWhen_CollateralThatDoesNotHaveDecimals(
        uint128 depositCap,
        uint120 loanToValue,
        address priceFeed
    )
        external
    {
        changePrank({ msgSender: users.owner.account });

        MockERC20WithNoDecimals collateralWithNoDecimals =
            new MockERC20WithNoDecimals({ name: "Collateral", symbol: "COL", deployerBalance: 100_000_000e18 });

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.InvalidMarginCollateralConfiguration.selector, address(collateralWithNoDecimals), 0, priceFeed
            )
        });

        perpsEngine.configureMarginCollateral(
            address(collateralWithNoDecimals), depositCap, loanToValue, priceFeed, MOCK_PRICE_FEED_HEARTBEAT_SECONDS
        );

        MockERC20WithZeroDecimals collateralWithZeroDecimals =
            new MockERC20WithZeroDecimals({ name: "Collateral", symbol: "COL", deployerBalance: 100_000_000e18 });

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.InvalidMarginCollateralConfiguration.selector, address(collateralWithZeroDecimals), 0, priceFeed
            )
        });

        perpsEngine.configureMarginCollateral(
            address(collateralWithZeroDecimals), depositCap, loanToValue, priceFeed, MOCK_PRICE_FEED_HEARTBEAT_SECONDS
        );
    }

    modifier whenCollateralThatHasDecimals() {
        _;
    }

    function testFuzz_RevertWhen_CollateralDecimalsIsGreaterThanSystemDecimals(
        uint128 depositCap,
        uint120 loanToValue
    )
        external
        whenCollateralThatHasDecimals
    {
        changePrank({ msgSender: users.owner.account });

        uint8 decimals = Constants.SYSTEM_DECIMALS + 1;
        address priceFeed = address(0x20);

        MockERC20 collateral =
            new MockERC20({ name: "Collateral", symbol: "COL", decimals_: decimals, deployerBalance: 100_000_000e18 });

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.InvalidMarginCollateralConfiguration.selector, address(collateral), decimals, priceFeed
            )
        });

        perpsEngine.configureMarginCollateral(
            address(collateral), depositCap, loanToValue, priceFeed, MOCK_PRICE_FEED_HEARTBEAT_SECONDS
        );
    }

    modifier whenCollateralDecimalsIsNotGreaterThanSystemDecimals() {
        _;
    }

    function testFuzz_RevertWhen_PriceFeedIsZero(
        uint128 depositCap,
        uint120 loanToValue
    )
        external
        whenCollateralThatHasDecimals
        whenCollateralDecimalsIsNotGreaterThanSystemDecimals
    {
        changePrank({ msgSender: users.owner.account });

        address priceFeed = address(0);

        MockERC20 collateral = new MockERC20({
            name: "Collateral",
            symbol: "COL",
            decimals_: Constants.SYSTEM_DECIMALS,
            deployerBalance: 100_000_000e18
        });

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.InvalidMarginCollateralConfiguration.selector,
                address(collateral),
                Constants.SYSTEM_DECIMALS,
                priceFeed
            )
        });

        perpsEngine.configureMarginCollateral(
            address(collateral), depositCap, loanToValue, priceFeed, MOCK_PRICE_FEED_HEARTBEAT_SECONDS
        );
    }

    modifier whenPriceFeedIsNotZero() {
        _;
    }

    function testFuzz_RevertWhen_PriceFeedHeartbeatSecondsIsZero(
        uint128 depositCap,
        uint120 loanToValue
    )
        external
        whenCollateralThatHasDecimals
        whenCollateralDecimalsIsNotGreaterThanSystemDecimals
        whenPriceFeedIsNotZero
    {
        changePrank({ msgSender: users.owner.account });

        address priceFeed = address(0);

        MockERC20 collateral = new MockERC20({
            name: "Collateral",
            symbol: "COL",
            decimals_: Constants.SYSTEM_DECIMALS,
            deployerBalance: 100_000_000e18
        });

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.InvalidMarginCollateralConfiguration.selector,
                address(collateral),
                Constants.SYSTEM_DECIMALS,
                priceFeed
            )
        });

        perpsEngine.configureMarginCollateral(address(collateral), depositCap, loanToValue, priceFeed, 0);
    }

    function testFuzz_WhenPriceFeedHeartbeatSecondsIsNotZero(
        uint128 depositCap,
        uint120 loanToValue
    )
        external
        whenCollateralThatHasDecimals
        whenCollateralDecimalsIsNotGreaterThanSystemDecimals
        whenPriceFeedIsNotZero
    {
        changePrank({ msgSender: users.owner.account });

        address priceFeed = address(0x20);

        MockERC20 collateral = new MockERC20({
            name: "Collateral",
            symbol: "COL",
            decimals_: Constants.SYSTEM_DECIMALS,
            deployerBalance: 100_000_000e18
        });

        // it should emit {LogConfigureMarginCollateral} event
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit GlobalConfigurationBranch.LogConfigureMarginCollateral(
            users.owner.account,
            address(collateral),
            depositCap,
            loanToValue,
            Constants.SYSTEM_DECIMALS,
            priceFeed,
            MOCK_PRICE_FEED_HEARTBEAT_SECONDS
        );

        // it should configure
        perpsEngine.configureMarginCollateral(
            address(collateral), depositCap, loanToValue, priceFeed, MOCK_PRICE_FEED_HEARTBEAT_SECONDS
        );
    }
}
