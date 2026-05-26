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
import { MockIRMTargets } from "./targets/MockIRMTargets.sol";
import { MorphoTargets } from "./targets/MorphoTargets.sol";
import { OracleMockTargets } from "./targets/OracleMockTargets.sol";

// Morpho
import {MarketParams} from "src/interfaces/IMorpho.sol";

abstract contract TargetFunctions is
    AdminTargets,
    DoomsdayTargets,
    ManagersTargets,
    MockIRMTargets,
    MorphoTargets,
    OracleMockTargets
{
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// === SET UP ENV HANDLERS === /// 

    function setup_switchCurrentLltv(uint8 index) public {
        // _switchCurrentLltv(uint256(index));
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///
}
