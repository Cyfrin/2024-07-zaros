// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Zaros dependencies
import { IAutomationCompatible } from "@zaros/external/chainlink/interfaces/IAutomationCompatible.sol";
import { IPerpsEngine } from "@zaros/perpetuals/PerpsEngine.sol";
import { Errors } from "@zaros/utils/Errors.sol";
import { BaseKeeper } from "../BaseKeeper.sol";

contract LiquidationKeeper is IAutomationCompatible, BaseKeeper {
    bytes32 internal constant LIQUIDATION_KEEPER_LOCATION = keccak256(
        abi.encode(uint256(keccak256("fi.zaros.external.chainlink.keepers.LiquidationKeeper")) - 1)
    ) & ~bytes32(uint256(0xff));

    /// @custom:storage-location erc7201:fi.zaros.external.chainlink.LiquidationKeeper
    /// @param perpsEngine The address of the PerpsEngine contract.
    struct LiquidationKeeperStorage {
        IPerpsEngine perpsEngine;
    }

    constructor() {
        _disableInitializers();
    }

    /// @notice {LiquidationKeeper} UUPS initializer.
    function initialize(address owner, IPerpsEngine perpsEngine) external initializer {
        __BaseKeeper_init(owner);

        if (address(perpsEngine) == address(0)) {
            revert Errors.ZeroInput("perpsEngine");
        }

        LiquidationKeeperStorage storage self = _getLiquidationKeeperStorage();
        self.perpsEngine = perpsEngine;
    }

    function getConfig() external view returns (address keeperOwner, address perpsEngine) {
        LiquidationKeeperStorage storage self = _getLiquidationKeeperStorage();

        keeperOwner = owner();
        perpsEngine = address(self.perpsEngine);
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (uint256 checkLowerBound, uint256 checkUpperBound, uint256 performLowerBound, uint256 performUpperBound) =
            abi.decode(checkData, (uint256, uint256, uint256, uint256));

        if (checkLowerBound >= checkUpperBound || performLowerBound >= performUpperBound) {
            revert Errors.InvalidBounds();
        }

        IPerpsEngine perpsEngine = _getLiquidationKeeperStorage().perpsEngine;
        uint128[] memory liquidatableAccountsIds =
            perpsEngine.checkLiquidatableAccounts(checkLowerBound, checkUpperBound);
        uint128[] memory accountsToBeLiquidated;

        if (liquidatableAccountsIds.length == 0 || liquidatableAccountsIds.length <= performLowerBound) {
            performData = abi.encode(accountsToBeLiquidated);

            return (upkeepNeeded, performData);
        }

        uint256 boundsDelta = performUpperBound - performLowerBound;
        uint256 performLength =
            boundsDelta > liquidatableAccountsIds.length ? liquidatableAccountsIds.length : boundsDelta;

        accountsToBeLiquidated = new uint128[](performLength);

        for (uint256 i; i < performLength; i++) {
            uint256 accountIdIndexAtLiquidatableAccounts = performLowerBound + i;
            if (accountIdIndexAtLiquidatableAccounts >= liquidatableAccountsIds.length) {
                break;
            }

            accountsToBeLiquidated[i] = liquidatableAccountsIds[accountIdIndexAtLiquidatableAccounts];
            if (!upkeepNeeded && liquidatableAccountsIds[accountIdIndexAtLiquidatableAccounts] != 0) {
                upkeepNeeded = true;
            }
        }

        bytes memory extraData = abi.encode(accountsToBeLiquidated, address(this));

        return (upkeepNeeded, extraData);
    }

    function setConfig(address perpsEngine) external onlyOwner {
        if (perpsEngine == address(0)) {
            revert Errors.ZeroInput("perpsEngine");
        }

        LiquidationKeeperStorage storage self = _getLiquidationKeeperStorage();

        self.perpsEngine = IPerpsEngine(perpsEngine);
    }

    function performUpkeep(bytes calldata peformData) external override onlyForwarder {
        uint128[] memory accountsToBeLiquidated = abi.decode(peformData, (uint128[]));
        LiquidationKeeperStorage storage self = _getLiquidationKeeperStorage();
        (IPerpsEngine perpsEngine) = (self.perpsEngine);

        perpsEngine.liquidateAccounts(accountsToBeLiquidated);
    }

    function _getLiquidationKeeperStorage() internal pure returns (LiquidationKeeperStorage storage self) {
        bytes32 slot = LIQUIDATION_KEEPER_LOCATION;

        assembly {
            self.slot := slot
        }
    }
}
