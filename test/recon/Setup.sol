// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";

// Managers
import {ActorManager} from "@recon/ActorManager.sol";
import {AssetManager} from "@recon/AssetManager.sol";

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

abstract contract Setup is BaseSetup, ActorManager, AssetManager, Utils {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using MarketParamsLib for MarketParams;

    MarketParams market;

    Morpho morpho;
    MockERC20 mockERC20;
    MockIRM mockIRM;
    OracleMock oracleMock;
    
    ///@notice The list of all markets being used
    EnumerableSet.Bytes32Set private _marketIds;
    mapping(bytes32 => MarketParams) private _marketData;
    
    ///@notice The list of all tokens being used
    EnumerableSet.AddressSet private _tokens;

    /// === Setup === ///
    /// This contains all calls to be performed in the tester constructor, both for Echidna and Foundry
    function setup() internal virtual override {
        morpho = new Morpho(address(this));
        oracleMock = new OracleMock();
        mockIRM = new MockIRM();

        // Deploy mock erc20 tokens (hardcoded at 3 env tokens for now)
        address token_18 = address(new MockERC20("Mock ERC20", "M-ERC20", 18));
        address token_6 = address(new MockERC20("Mock ERC20", "M-ERC20", 6));
        address token_0 = address(new MockERC20("Mock ERC20", "M-ERC20", 0));
        
        _tokens.add(token_18);
        _tokens.add(token_6);
        _tokens.add(token_0);
        
        // Set the first token as the current token
        mockERC20 = MockERC20(_tokens.at(0));

        // Label addresses
        vm.label(address(morpho), "Morpho");
        vm.label(address(oracleMock), "OracleMock");
        vm.label(address(mockIRM), "MockIRM");
        vm.label(token_18, "MockERC20_18");
        vm.label(token_6, "MockERC20_6");
        vm.label(token_0, "MockERC20_0");
    }

    /// === HELPERS === /// 
    /// @dev Using uint256 a base so we can let fuzzer freely explore
    /// @dev The handler can then bounding the search space first before accessing the set
    function _switchCurrentToken(uint256 index) internal {
        mockERC20 = MockERC20(_tokens.at(index));
    }

    /// @dev Atomically add market id and data
    /// @dev Returns false if market already exists (for assertion)
    function _addMarket(MarketParams memory marketParams) internal returns (bool) {
        Id marketId = marketParams.id();
        bytes32 marketIdBytes = Id.unwrap(marketId);
        //@follow-up Is it better to explicitly check from `.contains()` first? 
        //@follow-up Is it better to separate the add market id and data into two functions?
        if (!_marketIds.add(marketIdBytes)) {
            return false; // duplicate
        }
        _marketData[marketIdBytes] = marketParams;
        return true;
    }

    /// @dev Using uint256 a base so we can let fuzzer freely explore
    //// @dev The handler can then bounding the search space first before accessing the set 
    function _switchCurrentMarket(uint256 index) internal {
        // Switch the market params to the given index
        bytes32 marketId = _marketIds.at(index);
        MarketParams memory marketParams = _marketData[marketId];
        market = marketParams;
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
