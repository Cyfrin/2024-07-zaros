// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

library LookupTable {
    /// @notice ERC7201 storage location.
    bytes32 internal constant LOOKUP_TABLE_LOCATION =
        keccak256(abi.encode(uint256(keccak256("fi.zaros.perpetuals.LookupTable")) - 1)) & ~bytes32(uint256(0xff));

    struct Data {
        mapping(bytes4 interfaceId => bool isSupported) supportedInterfaces;
    }

    function load() internal pure returns (Data storage lookupTable) {
        bytes32 position = LOOKUP_TABLE_LOCATION;

        assembly {
            lookupTable.slot := position
        }
    }

    function addInterface(Data storage self, bytes4 interfaceId) internal {
        self.supportedInterfaces[interfaceId] = true;
    }

    function removeInterface(Data storage self, bytes4 interfaceId) internal {
        self.supportedInterfaces[interfaceId] = false;
    }
}
