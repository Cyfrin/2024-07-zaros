// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { MarketOrderKeeper } from "@zaros/external/chainlink/keepers/market-order/MarketOrderKeeper.sol";
import { LimitedMintingERC20 } from "testnet/LimitedMintingERC20.sol";
import { BaseScript } from "../Base.s.sol";

// Open Zeppelin dependencies
import { ERC1967Proxy } from "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import { UUPSUpgradeable } from "@openzeppelin/proxy/utils/UUPSUpgradeable.sol";

// Forge dependencies
import { console } from "forge-std/console.sol";

contract UpgradeUUPS is BaseScript {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/
    LimitedMintingERC20 internal usdc;
    LimitedMintingERC20 internal usdz;

    address internal forwarder;
    MarketOrderKeeper internal btcUsdMarketOrderKeeper;

    function run() public broadcaster {
        // usdc = LimitedMintingERC20(vm.envAddress("USDC"));

        btcUsdMarketOrderKeeper = MarketOrderKeeper(vm.envAddress("BTC_USD_MARKET_ORDER_KEEPER"));
        // forwarder = vm.envAddress("KEEPER_FORWARDER");
        // address newImplementation = address(new LimitedMintingERC20());
        address btcUsdMarketOrderKeeperNewImplementation = address(new MarketOrderKeeper());

        UUPSUpgradeable(address(btcUsdMarketOrderKeeper)).upgradeToAndCall(
            btcUsdMarketOrderKeeperNewImplementation, bytes("")
        );

        // btcUsdMarketOrderKeeper.setForwarder(forwarder);
    }
}
