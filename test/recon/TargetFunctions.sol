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

    /// @dev Using uint256 as we allow the fuzzer to create markets without a limit on number of markets
    /// @dev So let it explore (is it too loose?)
    function setup__switchCurrentMarket(uint256 index) public {
       _switchCurrentMarket(index);
    }

    /// @dev Using uint256 as we allow the fuzzer to add actors via successful supply without a limit on number of actors
    /// @dev So let it explore (is it too loose?)
    function setup_switchCurrentActor(uint256 index) public {
        _switchCurrentActor(index);
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///
}
