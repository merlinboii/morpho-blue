// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";

import {EnumerableSet} from "@recon/EnumerableSet.sol";

import {MarketParams, Id} from "src/interfaces/IMorpho.sol";
import {MarketParamsLib} from "src/libraries/MarketParamsLib.sol";

/// @dev Source of truth for the operable markets being used in the test
/// @notice No markets should be used in the suite without being added here first
abstract contract MarketManager {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using MarketParamsLib for MarketParams;

    /// @notice The current marketId for this set of variables
    bytes32 private __marketId;

    /// @notice Mapping of market ID to market params
    mapping(bytes32 => MarketParams) private _marketData;

    ///@notice The list of all markets being used
    EnumerableSet.Bytes32Set private _marketIds;

    // If the current target is bytes32(0) then it has not been setup yet and should revert
    error NotMarketSetup();
    // Market already exists
    error MarketExists();
    // Market does not exist
    error MarketNotAdded();

    /// @notice Returns the current active market params
    function _getMarket() internal view returns (MarketParams memory) {
        if (__marketId == bytes32(0)) {
            revert NotMarketSetup();
        }

        return _marketData[__marketId];
    }

    /// @notice Returns all market ids being used
    function _getMarketIds() internal view returns (bytes32[] memory) {
        return _marketIds.values();
    }

    /// @notice Adds a new market and adds it to the list of markets
    /// @param marketParams The market parameters
    function _addMarket(MarketParams memory marketParams) internal {
        Id targetId = marketParams.id();
        bytes32 targetIdBytes = Id.unwrap(targetId);

        if (_marketIds.contains(targetIdBytes)) {
            revert MarketExists();
        }

        _marketIds.add(targetIdBytes);
        _marketData[targetIdBytes] = marketParams;
    }

    /// @notice Removes a market from the list of markets
    function _removeMarket(bytes32 targetId) internal {
        if (!_marketIds.contains(targetId)) {
            revert MarketNotAdded();
        }

        _marketIds.remove(targetId);
        delete _marketData[targetId];
    }


    /// @notice Switches the current market id based on the entropy
    function _switchMarket(uint256 entropy) internal {
        bytes32 target = _marketIds.at(entropy);
        __marketId = target;
    }
}
