// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { MarginCollateralConfiguration } from "@zaros/perpetuals/leaves/MarginCollateralConfiguration.sol";

// PRB Math dependencies
import { UD60x18 } from "@prb-math/UD60x18.sol";

contract MarginCollateralConfigurationHarness {
    function workaround_getTotalDeposited(address collateralType) external view returns (uint256) {
        return MarginCollateralConfiguration.load(collateralType).totalDeposited;
    }

    function exposed_MarginCollateral_load(address collateralType)
        external
        pure
        returns (MarginCollateralConfiguration.Data memory)
    {
        return MarginCollateralConfiguration.load(collateralType);
    }

    function exposed_convertTokenAmountToUd60x18(
        address collateralType,
        uint256 amount
    )
        external
        view
        returns (UD60x18)
    {
        MarginCollateralConfiguration.Data storage self = MarginCollateralConfiguration.load(collateralType);
        return MarginCollateralConfiguration.convertTokenAmountToUd60x18(self, amount);
    }

    function exposed_convertUd60x18ToTokenAmount(
        address collateralType,
        UD60x18 amount
    )
        external
        view
        returns (uint256)
    {
        MarginCollateralConfiguration.Data storage self = MarginCollateralConfiguration.load(collateralType);
        return MarginCollateralConfiguration.convertUd60x18ToTokenAmount(self, amount);
    }

    function exposed_getPrice(address collateralType) external view returns (UD60x18) {
        MarginCollateralConfiguration.Data storage self = MarginCollateralConfiguration.load(collateralType);
        return MarginCollateralConfiguration.getPrice(self);
    }

    function exposed_configure(
        address collateralType,
        uint128 depositCap,
        uint120 loanToValue,
        uint8 decimals,
        address priceFeed,
        uint32 priceFeedHearbeatSeconds
    )
        external
    {
        MarginCollateralConfiguration.configure(
            collateralType, depositCap, loanToValue, decimals, priceFeed, priceFeedHearbeatSeconds
        );
    }
}
