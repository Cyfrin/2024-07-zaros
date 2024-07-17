// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { Base_Test } from "test/Base.t.sol";
import { MarketOrderKeeper } from "@zaros/external/chainlink/keepers/market-order/MarketOrderKeeper.sol";

contract MarketOrderKeeper_CheckCallback_Integration_Test is Base_Test {
    function test_WhenCheckCallbackIsCalled() external {
        MarketOrderKeeper marketOrderKeeper = new MarketOrderKeeper();

        bytes memory signedReport = abi.encode("signedReport");

        bytes[] memory values = new bytes[](3);
        values[0] = signedReport;
        values[1] = abi.encode(1);
        values[2] = abi.encode(2);

        bytes memory extraData = abi.encode("extraData");

        (bool upkeedNeeded, bytes memory performData) = marketOrderKeeper.checkCallback(values, extraData);

        (bytes memory signedReportReceived, bytes memory extraDataReceived) = abi.decode(performData, (bytes, bytes));

        // it should return upkeepNeeded
        assertEq(upkeedNeeded, true, "upkeedNeeded should be true");

        // it should return performData
        assertEq(signedReportReceived, signedReport, "signedReport is not correct");
        assertEq(extraDataReceived, extraData, "extraData is not correct");
    }
}
