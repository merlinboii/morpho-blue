// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import "src/Morpho.sol";

abstract contract MorphoTargets is
    BaseTargetFunctions,
    Properties
{
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///
    
    ////// CANARY FUNCTIONS - Check if sth work or not //////
    bool canaryBorrow;
    bool canaryCreateMarket;
    bool canaryLiquidate;
    bool canaryRepay;
    bool canarySupply;
    bool canarySupplyCollateral;
    bool canaryWithdraw;
    bool canaryWithdrawCollateral;

    /// @dev Check if morpho_borrow has successful call
    function canary_morpho_borrow() public {
        t(!canaryBorrow, "morpho_borrow called");
    }

    /// @dev Check if morpho_createMarket has successful call
    function canary_morpho_createMarket() public {
        t(!canaryCreateMarket, "morpho_createMarket called");
    }
    
    /// @dev Check if morpho_liquidate has successful call
    function canary_morpho_liquidate() public {
        t(!canaryLiquidate, "morpho_liquidate called");
    }
    
    /// @dev Check if morpho_repay has successful call
    function canary_morpho_repay() public {
        t(!canaryRepay, "morpho_repay called");
    }
    
    /// @dev Check if morpho_supply has successful call
    function canary_morpho_supply() public {
        t(!canarySupply, "morpho_supply called");
    }
    
    /// @dev Check if morpho_supplyCollateral has successful call
    function canary_morpho_supplyCollateral() public {
        t(!canarySupplyCollateral, "morpho_supplyCollateral called");
    }
    
    /// @dev Check if morpho_withdraw has successful call
    function canary_morpho_withdraw() public {
        t(!canaryWithdraw, "morpho_withdraw called");
    }
    
    /// @dev Check if morpho_withdrawCollateral has successful call
    function canary_morpho_withdrawCollateral() public {
        t(!canaryWithdrawCollateral, "morpho_withdrawCollateral called");
    }

    ////// CLAMP FUNCTIONS - Clamp inputs to valid ranges //////

    /// @dev Use currentActor as onBehalf (set by fuzzer via switch)
    function morpho_borrow_clamped(uint256 assets, uint256 shares, address receiver) public asActor {
        morpho_borrow(assets, shares, currentActor, receiver);
    }

    /// @dev Clamped function for morpho_createMarket
    /// @dev This will clamp the marketParams to using our hardcoded tokens
    /// @dev Hardcoded oracle and irm for simplicity (as now we only have 1 oracle and 1 irm)
    /// @dev We dont need to pass the whole marketParams as we are clamping it, we only the `lltv`
    /// @param collatIndex The index of the collateral token (uint8 as we only have 3 tokens)
    /// @param loanIndex The index of the loan token (uint8 as we only have 3 tokens)
    /// @param lltv The lltv to clamp
    function morpho_createMarket_clamped(uint8 collatIndex, uint8 loanIndex, uint256 lltv) public {
        //@follow-up should we mod the index to be within the range of tokens? so we avoid revert?
        address collateralToken = _getTokenAt(uint256(collatIndex));  //> this revert if not found
        address loanToken = _getTokenAt(uint256(loanIndex));          //> this revert if not found

        //@follow-up should we separate this to somewhere?
        if (!morpho.isLltvEnabled(lltv)) {
            morpho_enableLltv(lltv);
        }

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

    /// @dev Hardcoded empty data for liquidation (no callback triggered)
    /// @dev Use currentActor as borrower (set by fuzzer via switch)
    function morpho_liquidate_clamped(uint256 seizedAssets, uint256 repaidShares, bytes memory data) public {
       morpho_liquidate(currentActor, seizedAssets, repaidShares, "");
    }

    /// @dev Hardcoded empty data for liquidation (no callback triggered)
    /// @dev Use currentActor as onBehalf (set by fuzzer via switch)
    function morpho_repay_clamped(uint256 assets, uint256 shares) public {
        morpho_repay(assets, shares, currentActor, "");
    }

    /// @dev Hardcoded empty data for liquidation (no callback triggered)
    /// @dev Use currentActor as onBehalf (set by fuzzer via switch)
    function morpho_supply_clamped(uint256 assets, uint256 shares) public {
        morpho_supply(assets, shares, currentActor, "");
    }

    /// @dev Hardcoded empty data for liquidation (no callback triggered)
    /// @dev Use currentActor as onBehalf (set by fuzzer via switch)
    function morpho_supplyCollateral_clamped(uint256 assets) public {
        morpho_supplyCollateral(assets, currentActor, "");
    }

    /// @dev Hardcoded empty data for liquidation (no callback triggered)
    /// @dev Use currentActor as onBehalf (set by fuzzer via switch)
    function morpho_withdraw_clamped(uint256 assets, uint256 shares, address receiver) public {
        morpho_withdraw(assets, shares, currentActor, receiver);
    }

    /// @dev Hardcoded empty data for liquidation (no callback triggered)
    /// @dev Use currentActor as onBehalf (set by fuzzer via switch)
    function morpho_withdrawCollateral_clamped(uint256 assets, address receiver) public {
        morpho_withdrawCollateral(assets, currentActor, receiver);
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function morpho_accrueInterest() public asActor {
        morpho.accrueInterest(marketParams);
    }

    function morpho_borrow(uint256 assets, uint256 shares, address onBehalf, address receiver) public asActor {
        morpho.borrow(marketParams, assets, shares, onBehalf, receiver);

        canaryBorrow = true;
    }

    /// @dev Create Morpho market and record the market
    /// @dev Check if the marketId is duplicated
    /// @dev Applied to the base target because every clamped or overload fn that calls this base will have the same check, and the market will be added properly from all creation handlers
    function morpho_createMarket(MarketParams memory marketParams) public asActor {
        morpho.createMarket(marketParams);
        canaryCreateMarket = true;

        /// @dev morpho.createMarket() already block duplicate market creation, assert below again just in case
        t(_addMarket(marketParams), "duplicate market"); //if the above revert it this line will not be executed so only valid market got added
    }

    function morpho_enableIrm(address irm) public asActor {
        morpho.enableIrm(irm);
    }

    function morpho_enableLltv(uint256 lltv) public asActor {
        morpho.enableLltv(lltv);
    }

    function morpho_flashLoan(address token, uint256 assets, bytes memory data) public asActor {
        //TODO: the caller need to implement callback, but skip for now
        morpho.flashLoan(token, assets, data);
    }

    function morpho_liquidate(address borrower, uint256 seizedAssets, uint256 repaidShares, bytes memory data) public asActor {
        morpho.liquidate(marketParams, borrower, seizedAssets, repaidShares, data);

        canaryLiquidate = true;
    }

    function morpho_repay(uint256 assets, uint256 shares, address onBehalf, bytes memory data) public asActor {
        morpho.repay(marketParams, assets, shares, onBehalf, data);
        
        canaryRepay = true;
    }

    function morpho_setAuthorization(address authorized, bool newIsAuthorized) public asActor {
        morpho.setAuthorization(authorized, newIsAuthorized);
    }

    function morpho_setAuthorizationWithSig(Authorization memory authorization, Signature memory signature) public asActor {
        morpho.setAuthorizationWithSig(authorization, signature);
    }

    function morpho_setFee(uint256 newFee) public asActor {
        morpho.setFee(marketParams, newFee);
    }

    function morpho_setFeeRecipient(address newFeeRecipient) public asActor {
        morpho.setFeeRecipient(newFeeRecipient);
    }

    function morpho_setOwner(address newOwner) public asActor {
        morpho.setOwner(newOwner);
    }

    function morpho_supply(uint256 assets, uint256 shares, address onBehalf, bytes memory data) public asActor {
        morpho.supply(marketParams, assets, shares, onBehalf, data);

        canarySupply = true;
        /// @dev Add actor on supply/supplyCollateral as they are the first actions an actor can take to create position
        _tryAddActor(onBehalf);
    }

    function morpho_supplyCollateral(uint256 assets, address onBehalf, bytes memory data) public asActor {
        morpho.supplyCollateral(marketParams, assets, onBehalf, data);
        
        canarySupplyCollateral = true;

        /// @dev Add actor on supply/supplyCollateral as they are the first actions an actor can take to create position
        _tryAddActor(onBehalf);
    }

    function morpho_withdraw(uint256 assets, uint256 shares, address onBehalf, address receiver) public asActor {
        morpho.withdraw(marketParams, assets, shares, onBehalf, receiver);

        canaryWithdraw = true;
    }

    function morpho_withdrawCollateral(uint256 assets, address onBehalf, address receiver) public asActor {
        morpho.withdrawCollateral(marketParams, assets, onBehalf, receiver);
        
        canaryWithdrawCollateral = true;
    }
}