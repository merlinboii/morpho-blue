// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import "lib/setup-helpers/src/MockERC20.sol";

abstract contract MockERC20Targets is
    BaseTargetFunctions,
    Properties
{
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function mockERC20_approve(address spender, uint256 amount) public asActor {
        mockERC20.approve(spender, amount);
    }

    /// @dev Explicitly not exposing burn function
    // function mockERC20_burn(address from, uint256 value) public asActor {
    //     mockERC20.burn(from, value);
    // }

    function mockERC20_mint(address to, uint256 value) public asActor {
        mockERC20.mint(to, value);
    }

    function mockERC20_permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public asActor {
        mockERC20.permit(owner, spender, value, deadline, v, r, s);
    }

    function mockERC20_transfer(address to, uint256 amount) public asActor {
        mockERC20.transfer(to, amount);
    }

    function mockERC20_transferFrom(address from, address to, uint256 amount) public asActor {
        mockERC20.transferFrom(from, to, amount);
    }
}