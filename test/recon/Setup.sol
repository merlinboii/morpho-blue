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

abstract contract Setup is BaseSetup, ActorManager, AssetManager, Utils {
    using EnumerableSet for EnumerableSet.AddressSet;

    Morpho morpho;
    OracleMock oracleMock;
    MockIRM mockIRM;
    MockERC20 mockERC20;

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

    /// === SET UP ENV HANDLERS === ///    

    /// @dev Using uint8 as index so search space is limited to 256
    /// @dev As per our hardcoded 3 tokens, 256 stills allow fuzzer to try out-of-bound index access
    function setup_switchCurrentToken(uint8 index) public {
       mockERC20 = MockERC20(_tokens.at(index));
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
