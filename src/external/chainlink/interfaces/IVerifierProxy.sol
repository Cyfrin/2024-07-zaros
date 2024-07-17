// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { IFeeManager } from "./IFeeManager.sol";

interface IVerifierProxy {
    function verify(
        bytes calldata payload,
        bytes calldata parameterPayload
    )
        external
        payable
        returns (bytes memory verifierResponse);

    function s_feeManager() external view returns (IFeeManager);
}
