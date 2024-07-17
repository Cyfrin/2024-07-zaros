// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { FeeAsset } from "@zaros/external/chainlink/interfaces/IFeeManager.sol";

contract MockChainlinkFeeManager {
    function getFeeAndReward(
        address,
        bytes memory,
        address
    )
        external
        pure
        returns (FeeAsset memory, FeeAsset memory, uint256)
    {
        return
            (FeeAsset({ assetAddress: address(0), amount: 0 }), FeeAsset({ assetAddress: address(0), amount: 0 }), 0);
    }

    function i_nativeAddress() external pure returns (address) {
        return address(0);
    }
}
