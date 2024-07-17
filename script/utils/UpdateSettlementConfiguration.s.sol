// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { IVerifierProxy } from "@zaros/external/chainlink/interfaces/IVerifierProxy.sol";
import { IPerpsEngine } from "@zaros/perpetuals/PerpsEngine.sol";
import { SettlementConfiguration } from "@zaros/perpetuals/leaves/SettlementConfiguration.sol";
import { BaseScript } from "script/Base.s.sol";
import { ProtocolConfiguration } from "script/utils/ProtocolConfiguration.sol";

// Open Zeppelin dependencies
import { ERC1967Proxy } from "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import { UUPSUpgradeable } from "@openzeppelin/proxy/utils/UUPSUpgradeable.sol";

// Forge dependencies
import { console } from "forge-std/console.sol";

contract UpdateSettlementConfiguration is BaseScript, ProtocolConfiguration {
    /*//////////////////////////////////////////////////////////////////////////
                                    VARIABLES
    //////////////////////////////////////////////////////////////////////////*/
    bytes32 internal solUsdStreamId;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/
    IVerifierProxy internal chainlinkVerifier;
    address internal solUsdMarketOrderKeeper;
    IPerpsEngine internal perpsEngine;

    function run() public broadcaster {
        perpsEngine = IPerpsEngine(vm.envAddress("PERPS_ENGINE"));
        solUsdStreamId = vm.envBytes32("SOL_USD_STREAM_ID");
        chainlinkVerifier = IVerifierProxy(vm.envAddress("CHAINLINK_VERIFIER"));
        solUsdMarketOrderKeeper = vm.envAddress("SOL_USD_MARKET_ORDER_KEEPER");

        SettlementConfiguration.DataStreamsStrategy memory solUsdMarketOrderConfigurationData =
        SettlementConfiguration.DataStreamsStrategy({ chainlinkVerifier: chainlinkVerifier, streamId: solUsdStreamId });
        SettlementConfiguration.Data memory solUsdMarketOrderConfiguration = SettlementConfiguration.Data({
            strategy: SettlementConfiguration.Strategy.DATA_STREAMS_DEFAULT,
            isEnabled: true,
            fee: DEFAULT_SETTLEMENT_FEE,
            keeper: solUsdMarketOrderKeeper,
            data: abi.encode(solUsdMarketOrderConfigurationData)
        });

        perpsEngine.updateSettlementConfiguration(
            SOL_USD_MARKET_ID, SettlementConfiguration.MARKET_ORDER_CONFIGURATION_ID, solUsdMarketOrderConfiguration
        );
    }
}
