// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

// Targets
// NOTE: Always import and apply them in alphabetical order, so much easier to debug!
import { AdminTargets } from "./targets/AdminTargets.sol";
import { DoomsdayTargets } from "./targets/DoomsdayTargets.sol";
import { ManagersTargets } from "./targets/ManagersTargets.sol";
import { MockERC20Targets } from "./targets/MockERC20Targets.sol";
import { MockIRMTargets } from "./targets/MockIRMTargets.sol";
import { MorphoTargets } from "./targets/MorphoTargets.sol";
import { OracleMockTargets } from "./targets/OracleMockTargets.sol";

// Morpho
import {MarketParams} from "src/interfaces/IMorpho.sol";

abstract contract TargetFunctions is
    AdminTargets,
    DoomsdayTargets,
    ManagersTargets,
    MockERC20Targets,
    MockIRMTargets,
    MorphoTargets,
    OracleMockTargets
{
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// === SET UP ENV HANDLERS === ///

    /// @dev Using uint8 as index so search space is limited to 256
    /// @dev As per our hardcoded 3 tokens, 256 still allows the fuzzer to try out-of-bound index access   
    function setup_switchCurrentToken(uint8 index) public {
       _switchCurrentToken(uint256(index));
    }

    /// @dev Using uint256 as we allow the fuzzer to create markets without a limit on market amount
    /// @dev So let it explore (is it too loose?)
    function setup__switchCurrentMarket(uint256 index) public {
       _switchCurrentMarket(index);
    }

    /// @dev Clamped function for morpho_createMarket
    /// @dev This will clamp the marketParams to using our hardcoded tokens
    /// @dev Hardcoded oracle and irm for simplicity (as now we only have 1 oracle and 1 irm)
    /// @dev We dont need to pass the whole marketParams as we are clamping it, we only the `lltv`
    /// @param collatIndex The index of the collateral token (uint8 as we only have 3 tokens)
    /// @param loanIndex The index of the loan token (uint8 as we only have 3 tokens)
    /// @param lltv The lltv to clamp
    function morpho_createMarket_clamped(uint8 collatIndex, uint8 loanIndex, uint8 lltv) public {
        //@follow-up should we mod the index to be within the range of tokens? so we avoid revert?
        address collateralToken = _getTokenAt(uint256(collatIndex));  //> this revert if not found
        address loanToken = _getTokenAt(uint256(loanIndex));          //> this revert if not found
    
        // Create marketParams with clamped values
        MarketParams memory clampedParams = MarketParams({
            loanToken: loanToken,
            collateralToken: collateralToken,
            oracle: address(mockOracle),
            irm: address(mockIRM),
            lltv: lltv
        });
        
        morpho_createMarket(clampedParams);
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///
}
