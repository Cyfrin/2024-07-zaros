// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { IPerpsEngine } from "@zaros/perpetuals/PerpsEngine.sol";
import { ILogAutomation, Log as AutomationLog } from "../../interfaces/ILogAutomation.sol";
import { IStreamsLookupCompatible } from "../../interfaces/IStreamsLookupCompatible.sol";
import { BaseKeeper } from "../BaseKeeper.sol";
import { Errors } from "@zaros/utils/Errors.sol";
import { MarketOrder } from "@zaros/perpetuals/leaves/MarketOrder.sol";

// Open Zeppelin dependencies
import { SafeCast } from "@openzeppelin/utils/math/SafeCast.sol";

contract MarketOrderKeeper is ILogAutomation, IStreamsLookupCompatible, BaseKeeper {
    using SafeCast for uint256;

    /// @notice ERC7201 storage location.
    bytes32 internal constant MARKET_ORDER_KEEPER_LOCATION = keccak256(
        abi.encode(uint256(keccak256("fi.zaros.external.chainlink.keepers.MarketOrderKeeper")) - 1)
    ) & ~bytes32(uint256(0xff));

    /// @notice index of the account id param at LogCreateMarketOrder.
    uint256 internal constant LOG_CREATE_MARKET_ORDER_ACCOUNT_ID_INDEX = 2;

    string public constant DATA_STREAMS_FEED_LABEL = "feedIDs";
    string public constant DATA_STREAMS_QUERY_LABEL = "timestamp";

    /// @custom:storage-location erc7201:fi.zaros.external.chainlink.MarketOrderKeeper
    /// @param perpsEngine The address of the PerpsEngine contract.
    /// @param marketId The perps market id that the keeper should fill market orders for.
    /// @param streamId The Chainlink Data Streams stream id.
    struct MarketOrderKeeperStorage {
        IPerpsEngine perpsEngine;
        uint128 marketId;
        string streamId;
    }

    constructor() {
        _disableInitializers();
    }

    /// @notice {MarketOrderKeeper} UUPS initializer.
    /// @param owner The address of the owner of the keeper.
    /// @param perpsEngine The address of the PerpsEngine contract.
    /// @param marketId The perps market id that the keeper should fill market orders for.
    function initialize(
        address owner,
        IPerpsEngine perpsEngine,
        uint128 marketId,
        string calldata streamId
    )
        external
        initializer
    {
        __BaseKeeper_init(owner);

        if (address(perpsEngine) == address(0)) {
            revert Errors.ZeroInput("perpsEngine");
        }
        if (marketId == 0) {
            revert Errors.ZeroInput("marketId");
        }
        if (bytes(streamId).length == 0) {
            revert Errors.ZeroInput("streamId");
        }

        MarketOrderKeeperStorage storage self = _getMarketOrderKeeperStorage();

        self.perpsEngine = perpsEngine;
        self.marketId = marketId;
        self.streamId = streamId;
    }

    function getConfig()
        external
        view
        returns (address keeperOwner, address forwarder, address perpsEngine, uint128 marketId)
    {
        BaseKeeperStorage storage baseKeeperStorage = _getBaseKeeperStorage();
        MarketOrderKeeperStorage storage self = _getMarketOrderKeeperStorage();

        keeperOwner = owner();
        forwarder = baseKeeperStorage.forwarder;
        perpsEngine = address(self.perpsEngine);
        marketId = self.marketId;
    }

    // function checkErrorHandler(
    //     uint256 errorCode,
    //     bytes memory extraData
    // )
    //     external
    //     pure
    //     returns (bool upkeepNeeded, bytes memory performData)
    // {
    //     return (true, abi.encode(errorCode));
    // }

    /// @inheritdoc ILogAutomation
    function checkLog(
        AutomationLog calldata log,
        bytes calldata
    )
        external
        view
        override
        returns (bool, bytes memory)
    {
        uint128 tradingAccountId = uint256(log.topics[LOG_CREATE_MARKET_ORDER_ACCOUNT_ID_INDEX]).toUint128();
        (MarketOrder.Data memory marketOrder) = abi.decode(log.data, (MarketOrder.Data));

        MarketOrderKeeperStorage storage self = _getMarketOrderKeeperStorage();

        string[] memory streams = new string[](1);
        streams[0] = self.streamId;
        uint256 settlementTimestamp = marketOrder.timestamp;
        bytes memory extraData = abi.encode(tradingAccountId);

        revert StreamsLookup(
            DATA_STREAMS_FEED_LABEL, streams, DATA_STREAMS_QUERY_LABEL, settlementTimestamp, extraData
        );
    }

    function checkCallback(
        bytes[] calldata values,
        bytes calldata extraData
    )
        external
        pure
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        bytes memory signedReport = values[0];

        upkeepNeeded = true;
        performData = abi.encode(signedReport, extraData);
    }

    /// @notice Updates the market order keeper configuration.
    /// @param perpsEngine The address of the PerpsEngine contract.
    /// @param marketId The perps market id that the keeper should fill market orders for.
    function updateConfig(IPerpsEngine perpsEngine, uint128 marketId, string calldata streamId) external onlyOwner {
        if (address(perpsEngine) == address(0)) {
            revert Errors.ZeroInput("perpsEngine");
        }
        if (marketId == 0) {
            revert Errors.ZeroInput("marketId");
        }
        if (bytes(streamId).length == 0) {
            revert Errors.ZeroInput("streamId");
        }

        MarketOrderKeeperStorage storage self = _getMarketOrderKeeperStorage();
        self.perpsEngine = perpsEngine;
        self.marketId = marketId;
        self.streamId = streamId;
    }

    /// @inheritdoc ILogAutomation
    function performUpkeep(bytes calldata performData) external onlyForwarder {
        (bytes memory signedReport, bytes memory extraData) = abi.decode(performData, (bytes, bytes));
        uint128 tradingAccountId = abi.decode(extraData, (uint128));

        MarketOrderKeeperStorage storage self = _getMarketOrderKeeperStorage();
        (IPerpsEngine perpsEngine, uint128 marketId) = (self.perpsEngine, self.marketId);

        perpsEngine.fillMarketOrder(tradingAccountId, marketId, signedReport);
    }

    function _getMarketOrderKeeperStorage() internal pure returns (MarketOrderKeeperStorage storage self) {
        bytes32 slot = MARKET_ORDER_KEEPER_LOCATION;

        assembly {
            self.slot := slot
        }
    }
}
