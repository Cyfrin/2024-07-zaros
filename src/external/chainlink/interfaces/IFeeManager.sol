// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

struct FeeAsset {
    address assetAddress;
    uint256 amount;
}

interface IFeeManager {
    function getFeeAndReward(
        address subscriber,
        bytes memory report,
        address quoteAddress
    )
        external
        returns (FeeAsset memory, FeeAsset memory, uint256);

    function i_linkAddress() external view returns (address);

    function i_nativeAddress() external view returns (address);

    function i_rewardManager() external view returns (address);
}
