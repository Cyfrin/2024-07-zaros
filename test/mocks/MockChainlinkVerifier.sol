// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { IFeeManager } from "@zaros/external/chainlink/interfaces/IFeeManager.sol";

contract MockChainlinkVerifier {
    IFeeManager public immutable s_feeManager;

    constructor(IFeeManager feeManager) {
        s_feeManager = feeManager;
    }

    function verify(
        bytes calldata payload,
        bytes calldata
    )
        external
        payable
        returns (bytes memory verifierResponse)
    {
        (, bytes memory verifiedReportData) = abi.decode(payload, (bytes32[3], bytes));

        verifierResponse = verifiedReportData;
    }
}
