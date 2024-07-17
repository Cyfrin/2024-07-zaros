// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { Errors } from "@zaros/utils/Errors.sol";
import { Base_Test } from "test/Base.t.sol";
import { TradingAccountBranch } from "@zaros/perpetuals/branches/TradingAccountBranch.sol";
import { MockERC20 } from "test/mocks/MockERC20.sol";

contract DepositMargin_Integration_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();
    }

    function test_RevertWhen_TheAmountIsZero() external {
        uint256 amountToDeposit = 0;
        uint128 userTradingAccountId = perpsEngine.createTradingAccount(bytes(""), false);

        // it should revert
        vm.expectRevert({ revertData: abi.encodeWithSelector(Errors.ZeroInput.selector, "amount") });

        perpsEngine.depositMargin(userTradingAccountId, address(usdc), amountToDeposit);
    }

    modifier whenTheAmountIsNotZero() {
        _;
    }

    function testFuzz_RevertGiven_TheCollateralTypeHasInsufficientDepositCap(uint256 amountToDeposit)
        external
        whenTheAmountIsNotZero
    {
        // 18 token decimals Scenarios: when user deposit more than the deposit cap by adding up all deposits

        uint256 amountToDepositMargin = WSTETH_DEPOSIT_CAP_X18.intoUint256();
        deal({ token: address(wstEth), to: users.naruto.account, give: amountToDepositMargin * 2 });

        uint128 userTradingAccountId = perpsEngine.createTradingAccount(bytes(""), false);

        perpsEngine.depositMargin(userTradingAccountId, address(wstEth), amountToDepositMargin);

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.DepositCap.selector, address(wstEth), amountToDepositMargin, WSTETH_DEPOSIT_CAP_X18.intoUint128()
            )
        });

        perpsEngine.depositMargin(userTradingAccountId, address(wstEth), amountToDepositMargin);

        // scenario: the collateral type has insufficient deposit cap

        amountToDeposit = bound({
            x: amountToDeposit,
            min: WSTETH_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(wstEth), WSTETH_DEPOSIT_CAP_X18)
        });
        deal({ token: address(wstEth), to: users.naruto.account, give: amountToDeposit });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.configureMarginCollateral(
            address(wstEth),
            0,
            WSTETH_LOAN_TO_VALUE,
            marginCollaterals[WSTETH_MARGIN_COLLATERAL_ID].priceFeed,
            MOCK_PRICE_FEED_HEARTBEAT_SECONDS
        );
        changePrank({ msgSender: users.naruto.account });

        userTradingAccountId = perpsEngine.createTradingAccount(bytes(""), false);

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.DepositCap.selector, address(wstEth), amountToDeposit, 0)
        });

        perpsEngine.depositMargin(userTradingAccountId, address(wstEth), amountToDeposit);

        // Usdc Scenarios: the collateral type has 6 decimals (usdc)

        uint256 amountToDepositMarginUsdc = convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18);
        deal({ token: address(usdc), to: users.naruto.account, give: amountToDepositMarginUsdc * 2 });

        perpsEngine.depositMargin(userTradingAccountId, address(usdc), amountToDepositMarginUsdc);

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.DepositCap.selector,
                address(usdc),
                convertTokenAmountToUd60x18(address(usdc), amountToDepositMarginUsdc).intoUint256(),
                USDC_DEPOSIT_CAP_X18.intoUint256()
            )
        });

        perpsEngine.depositMargin(userTradingAccountId, address(usdc), amountToDepositMarginUsdc);

        // scenario: the collateral type has insufficient deposit cap

        amountToDeposit = convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18);
        deal({ token: address(usdc), to: users.naruto.account, give: amountToDeposit });

        changePrank({ msgSender: users.owner.account });
        perpsEngine.configureMarginCollateral(
            address(usdc),
            0,
            USDC_LOAN_TO_VALUE,
            marginCollaterals[USDC_MARGIN_COLLATERAL_ID].priceFeed,
            MOCK_PRICE_FEED_HEARTBEAT_SECONDS
        );
        changePrank({ msgSender: users.naruto.account });

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.DepositCap.selector, address(usdc), convertTokenAmountToUd60x18(address(usdc), amountToDeposit), 0
            )
        });

        perpsEngine.depositMargin(userTradingAccountId, address(usdc), amountToDeposit);
    }

    modifier givenTheCollateralTypeHasSufficientDepositCap() {
        _;
    }

    function testFuzz_RevertGiven_TheCollateralTypeIsNotInTheLiquidationPriority(uint256 amountToDeposit)
        external
        whenTheAmountIsNotZero
        givenTheCollateralTypeHasSufficientDepositCap
    {
        amountToDeposit = bound({
            x: amountToDeposit,
            min: 1,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });
        deal({ token: address(usdc), to: users.naruto.account, give: amountToDeposit });

        changePrank({ msgSender: users.owner.account });

        perpsEngine.removeCollateralFromLiquidationPriority(address(usdc));

        changePrank({ msgSender: users.naruto.account });

        uint128 userTradingAccountId = perpsEngine.createTradingAccount(bytes(""), false);

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(Errors.CollateralLiquidationPriorityNotDefined.selector, address(usdc))
        });
        perpsEngine.depositMargin(userTradingAccountId, address(usdc), amountToDeposit);
    }

    modifier givenTheCollateralTypeIsInTheLiquidationPriority() {
        _;
    }

    function testFuzz_RevertGiven_TheTradingAccountDoesNotExist(
        uint128 userTradingAccountId,
        uint256 amountToDeposit
    )
        external
        whenTheAmountIsNotZero
        givenTheCollateralTypeHasSufficientDepositCap
        givenTheCollateralTypeIsInTheLiquidationPriority
    {
        amountToDeposit = bound({
            x: amountToDeposit,
            min: 1,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });
        deal({ token: address(usdc), to: users.naruto.account, give: amountToDeposit });

        // it should revert
        vm.expectRevert({
            revertData: abi.encodeWithSelector(
                Errors.AccountNotFound.selector, userTradingAccountId, users.naruto.account
            )
        });

        perpsEngine.depositMargin(userTradingAccountId, address(usdc), amountToDeposit);
    }

    function testFuzz_GivenTheTradingAccountExists(uint256 amountToDeposit)
        external
        whenTheAmountIsNotZero
        givenTheCollateralTypeHasSufficientDepositCap
        givenTheCollateralTypeIsInTheLiquidationPriority
    {
        // Test with usdc that has 6 decimals

        assertEq(MockERC20(address(usdc)).balanceOf(users.naruto.account), 0, "initial balance should be zero");

        amountToDeposit = bound({
            x: amountToDeposit,
            min: USDC_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(usdc), USDC_DEPOSIT_CAP_X18)
        });
        deal({ token: address(usdc), to: users.naruto.account, give: amountToDeposit });

        assertEq(
            MockERC20(address(usdc)).balanceOf(users.naruto.account), amountToDeposit, "balanceOf is not correct"
        );

        uint128 userTradingAccountId = perpsEngine.createTradingAccount(bytes(""), false);

        // it should emit {LogDepositMargin}
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit TradingAccountBranch.LogDepositMargin(
            users.naruto.account, userTradingAccountId, address(usdc), amountToDeposit
        );

        // it should transfer the amount from the sender to the trading account
        expectCallToTransferFrom(usdc, users.naruto.account, address(perpsEngine), amountToDeposit);
        perpsEngine.depositMargin(userTradingAccountId, address(usdc), amountToDeposit);

        assertEq(MockERC20(address(usdc)).balanceOf(users.naruto.account), 0, "balanceOf should be zero");

        uint256 newMarginCollateralBalance = convertUd60x18ToTokenAmount(
            address(usdc), perpsEngine.getAccountMarginCollateralBalance(userTradingAccountId, address(usdc))
        );

        // it should increase the amount of margin collateral
        assertEq(newMarginCollateralBalance, amountToDeposit, "depositMargin");

        // Test with wstEth that has 18 decimals

        assertEq(MockERC20(wstEth).balanceOf(users.naruto.account), 0, "initial balance should be zero");

        amountToDeposit = bound({
            x: amountToDeposit,
            min: WSTETH_MIN_DEPOSIT_MARGIN,
            max: convertUd60x18ToTokenAmount(address(wstEth), WSTETH_DEPOSIT_CAP_X18)
        });
        deal({ token: address(wstEth), to: users.naruto.account, give: amountToDeposit });

        assertEq(MockERC20(wstEth).balanceOf(users.naruto.account), amountToDeposit, "balanceOf is not correct");

        // it should emit {LogDepositMargin}
        vm.expectEmit({ emitter: address(perpsEngine) });
        emit TradingAccountBranch.LogDepositMargin(
            users.naruto.account, userTradingAccountId, address(wstEth), amountToDeposit
        );

        // it should transfer the amount from the sender to the trading account
        expectCallToTransferFrom(wstEth, users.naruto.account, address(perpsEngine), amountToDeposit);
        perpsEngine.depositMargin(userTradingAccountId, address(wstEth), amountToDeposit);

        assertEq(MockERC20(wstEth).balanceOf(users.naruto.account), 0, "balanceOf should be zero");

        newMarginCollateralBalance = convertUd60x18ToTokenAmount(
            address(wstEth), perpsEngine.getAccountMarginCollateralBalance(userTradingAccountId, address(wstEth))
        );

        // it should increase the amount of margin collateral
        assertEq(newMarginCollateralBalance, amountToDeposit, "depositMargin");
    }
}
