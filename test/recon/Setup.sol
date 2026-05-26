// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";

// Managers
import {ActorManager} from "@recon/ActorManager.sol";
import {AssetManager} from "@recon/AssetManager.sol";

import {MarketManager} from "./managers/MarketManager.sol";
// Helpers
import {Utils} from "@recon/Utils.sol";

// Your deps
import {Morpho} from "src/Morpho.sol";

// mocks
import {MockIRM} from "./mocks/MockIRM.sol";
import {MockERC20} from "lib/setup-helpers/src/MockERC20.sol";
import {OracleMock} from "src/mocks/OracleMock.sol";

// helpers
import {EnumerableSet} from "@recon/EnumerableSet.sol";
import {MarketParams, Id} from "src/interfaces/IMorpho.sol";
import {MarketParamsLib} from "src/libraries/MarketParamsLib.sol";

abstract contract Setup is BaseSetup, ActorManager, AssetManager, MarketManager, Utils {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using MarketParamsLib for MarketParams;

    uint256 currentLltv;
    MarketParams marketParams;

    Morpho morpho;
    MockIRM mockIRM;
    OracleMock mockOracle;
    
    ///@notice The list of all lltvs being used
    /// @dev `_lltvs` is only used as the clamp set for clamped market creation.
    /// @dev It does not track every LLTV enabled in Morpho.
    /// @dev LLTV is not part of the operable-market check. If `createMarket` succeeds, the LLTV is considered valid for this harness.
    EnumerableSet.UintSet private _lltvs;

    /// === Setup === ///
    /// This contains all calls to be performed in the tester constructor, both for Echidna and Foundry
    function setup() internal virtual override {
        morpho = new Morpho(address(this));
        mockOracle = new OracleMock();
        mockIRM = new MockIRM();

        // Enable and add IRM
        morpho.enableIrm(address(mockIRM));

        /// @dev Governance-approved LLTVs from https://docs.morpho.org/learn/concepts/market/#lltvs
        _lltvs.add(0);                  // 0%
        _lltvs.add(385000000000000000); // 38.5%
        _lltvs.add(625000000000000000); // 62.5%
        _lltvs.add(770000000000000000); // 77%
        _lltvs.add(860000000000000000); // 86%
        _lltvs.add(915000000000000000); // 91.5%
        _lltvs.add(945000000000000000); // 94.5%
        _lltvs.add(965000000000000000); // 96.5%
        _lltvs.add(980000000000000000); // 98%

        // Enable all LLTVs
        for (uint256 i = 0; i < _lltvs.length(); i++) {
            morpho.enableLltv(_lltvs.at(i));
        }

        currentLltv = _lltvs.at(4);
        
        // Deploy mock erc20 tokens (hardcoded at 3 env tokens for now)
        _setupAssets();

        // Add initial multiple actors and seed them the tokens
        _setupActors();
        
        // Label addresses
        vm.label(address(morpho), "Morpho");
        vm.label(address(mockOracle), "OracleMock");
        vm.label(address(mockIRM), "MockIRM");
    }

    /// === HELPERS === /// 

    /// @dev this will reduce the fuzzer work to have sequence on mint and approve 
    /// @dev it will also set the approval for all actors to morpho
    function _setupActors() internal {
        _addActor(address(this));
        _addActor(address(0x12));
        _addActor(address(0x34));
        _addActor(address(0x56));
        _addActor(address(0xff));
        
        address[] memory actorsArray = _getActors();
        address[] memory approvalArray =  new address[](actorsArray.length);
        for (uint256 i = 0; i < actorsArray.length; i++) {
            approvalArray[i] = address(morpho);
        }
        uint256 mintAmount = type(uint88).max;
        _finalizeAssetDeployment(actorsArray, approvalArray, mintAmount);
    }

    function _setupAssets() internal {
        _newAsset(0);
        _newAsset(6);
        _newAsset(18);
    }

    /// @dev Using uint256 a base so we can let fuzzer freely explore
    function _switchCurrentLltv(uint256 index) internal {
        currentLltv = _getLltvAt(index);
    }
    
    /// @dev Get LLTV by index, reverts if out of bounds
    function _getLltvAt(uint256 index) internal view returns (uint256) {
        return _lltvs.at(index);
    }

    /// === MODIFIERS === ///
    /// Prank admin and actor
    
    modifier asAdmin {
        vm.prank(address(this));
        _;
    }

    modifier asActor {
        vm.prank(address(_getActor()));
        _;
    }
}
