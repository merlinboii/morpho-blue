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
    using EnumerableSet for EnumerableSet.UintSet;
    using MarketParamsLib for MarketParams;

    uint256 constant INITIAL_BALANCE_WHOLE = 100_000_000;

    address currentActor;
    uint256 currentLltv;
    MarketParams marketParams;

    Morpho morpho;
    MockERC20 mockERC20;
    MockIRM mockIRM;
    OracleMock mockOracle;
    
    ///@notice The list of all actors being used
    EnumerableSet.AddressSet private _actors;

    ///@notice The list of all irms being used
    EnumerableSet.AddressSet private _irms;

    ///@notice The list of all lltvs being used
    /// @dev `_lltvs` is only used as the clamp set for clamped market creation.
    /// @dev It does not track every LLTV enabled in Morpho.
    /// @dev LLTV is not part of the operable-market check. If `createMarket` succeeds, the LLTV is considered valid for this harness.
    EnumerableSet.UintSet private _lltvs;

    ///@notice The list of all markets being used
    EnumerableSet.Bytes32Set private _marketIds;
    ///@dev This contains all **operable** markets that our harness can operate on
    EnumerableSet.Bytes32Set private _operableMarketIds;
    mapping(bytes32 => MarketParams) private _marketData;
    
    ///@notice The list of all oracles being used
    EnumerableSet.AddressSet private _oracles;

    ///@notice The list of all tokens being used
    EnumerableSet.AddressSet private _tokens;

    /// === Setup === ///
    /// This contains all calls to be performed in the tester constructor, both for Echidna and Foundry
    function setup() internal virtual override {
        morpho = new Morpho(address(this));
        mockOracle = new OracleMock();
        mockIRM = new MockIRM();

        // Add Oracle
        _oracles.add(address(mockOracle));

        // Enable and add IRM
        morpho.enableIrm(address(mockIRM));
        _irms.add(address(mockIRM));

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
        address token_18 = address(new MockERC20("Mock ERC20", "M-ERC20", 18));
        address token_6 = address(new MockERC20("Mock ERC20", "M-ERC20", 6));
        address token_0 = address(new MockERC20("Mock ERC20", "M-ERC20", 0));
        
        _tokens.add(token_18);
        _tokens.add(token_6);
        _tokens.add(token_0);

        // Set the first token as the current token
        mockERC20 = MockERC20(_getTokenAt(0));

        // Add initial multiple actors and seed them the tokens
        _setUpActors();
        
        // Set the first actor as the current actor
        currentActor = _getActorAt(0);
        
        // Label addresses
        vm.label(address(morpho), "Morpho");
        vm.label(address(mockOracle), "OracleMock");
        vm.label(address(mockIRM), "MockIRM");
        vm.label(token_18, "MockERC20_18");
        vm.label(token_6, "MockERC20_6");
        vm.label(token_0, "MockERC20_0");
    }

    /// === HELPERS === /// 

    /// @dev this will reduce the fuzzer work to have sequence on mint and approve
    function _setUpActors() internal {
        _actors.add(address(this));
        _actors.add(address(0x12));
        _actors.add(address(0x34));
        _actors.add(address(0x56));
        _actors.add(address(0xff));
        
        for(uint256 i = 0; i < _actors.length(); i++) {
            address actor = _getActorAt(i);

            for(uint256 j = 0; j < _tokens.length(); j++) {
                MockERC20 _token = MockERC20(_getTokenAt(j));
                _token.mint(actor, INITIAL_BALANCE_WHOLE * 10**_token.decimals());

                vm.prank(actor);
                _token.approve(address(morpho), type(uint256).max);
            }
        }
    }

    /// @dev Using uint256 a base so we can let fuzzer freely explore
    /// @dev The handler can then bounding the search space first before accessing the set
    function _switchCurrentToken(uint256 index) internal {
        mockERC20 = MockERC20(_getTokenAt(index));
    }

    /// @dev Using uint256 a base so we can let fuzzer freely explore
    /// @dev The handler can then bounding the search space first before accessing the set
    /// @dev revert if the index is out of bound
    function _getTokenAt(uint256 index) internal view returns (address) {
        return _tokens.at(index);
    }

    /// @dev Using uint256 a base so we can let fuzzer freely explore
    function _switchCurrentActor(uint256 index) internal {
        currentActor = _getActorAt(index);
    }

    function _getActorAt(uint256 index) internal view returns (address) {
        return _actors.at(index);
    }

    /// @dev Silent revert if actor already exists
    function _tryAddActor(address actor) internal {
        _actors.add(actor);
    }

    /// @dev Using uint256 a base so we can let fuzzer freely explore
    function _switchCurrentLltv(uint256 index) internal {
        currentLltv = _getLltvAt(index);
    }
    
    /// @dev Get LLTV by index, reverts if out of bounds
    function _getLltvAt(uint256 index) internal view returns (uint256) {
        return _lltvs.at(index);
    }

    /// @dev Try add LLTV, silent revert if already exists
    /// @dev Can expose under morpho_enableLltv for further fuzzing of lltv combination
    function _tryAddLltv(uint256 lltv) internal {
        _lltvs.add(lltv);
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

        if (_isOperableMarket(marketParams)) {
            _addOperableMarket(marketIdBytes);
        }

        return true;
    }

    /// @dev Check if market is operable
    function _isOperableMarket(MarketParams memory marketParams) internal view returns (bool) {
        bool isLoanTokenOperable = _tokens.contains(marketParams.loanToken);
        bool isCollateralTokenOperable = _tokens.contains(marketParams.collateralToken);
        bool isIRMOperable = _irms.contains(marketParams.irm);
        bool isOracleOperable = _oracles.contains(marketParams.oracle);
        return isLoanTokenOperable && isCollateralTokenOperable && isIRMOperable && isOracleOperable;
    }
    
    /// @dev Add market to operable set
    function _addOperableMarket(bytes32 marketId) internal {
        _operableMarketIds.add(marketId);
    }

    /// @dev Using uint256 a base so we can let fuzzer freely explore
    //// @dev The handler can then bounding the search space first before accessing the set 
    function _switchCurrentMarket(uint256 index) internal {
        // Switch the market params to the given index
        bytes32 marketId = _marketIds.at(index);
        MarketParams memory _marketParams = _marketData[marketId];
        marketParams = _marketParams;
    }

    /// @dev Using uint256 a base so we can let fuzzer freely explore
    //// @dev The handler can then bounding the search space first before accessing the set 
    function _switchCurrentOperableMarket(uint256 index) internal {
        // Switch the market params to the given index
        bytes32 marketId = _operableMarketIds.at(index);
        MarketParams memory _marketParams = _marketData[marketId];
        marketParams = _marketParams;
    }

    function _marketParamsToId(MarketParams memory marketParams) internal pure returns (Id) {
        return marketParams.id();
    }

    /// === MODIFIERS === ///
    /// Prank admin and actor
    
    modifier asAdmin {
        vm.prank(address(this));
        _;
    }

    modifier asActor {
        // vm.prank(address(_getActor()));
        vm.prank(currentActor);
        _;
    }
}
