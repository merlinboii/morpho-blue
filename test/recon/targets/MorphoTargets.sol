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
    
    //////////// CANARY FUNCTIONS - Check if sth work or not ////////////
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

    //////////// CLAMP FUNCTIONS - Clamp inputs to valid ranges ////////////

    /// @dev Use currentActor as onBehalf (set by fuzzer via switch)
    function morpho_borrow_clamped(uint256 assets, uint256 shares, address receiver) public asActor {
        morpho_borrow(assets, shares, currentActor, receiver);
    }

    /// @dev Clamped `onBehalf` and `assets` amount
    function morpho_borrow_clamped_byShares(uint256 shares, address receiver) public {
        morpho_borrow(0, shares, currentActor, receiver);
    }

    /// @dev Clamped `onBehalf` and `shares` amount
    function morpho_borrow_clamped_byAssets(uint256 assets, address receiver) public {
        //@follow-up this way we focus only on execute as self-borrower as same as self-iquidation
        morpho_borrow(assets, 0, currentActor, receiver);
    }

    /// @dev Clamped function for morpho_createMarket using governance-approved LLTVs
    /// @dev ref: https://docs.morpho.org/learn/concepts/market/#lltvs
    /// @dev Fuzzer picks LLTV from setup values via switching
    /// @dev Reduces (lltv, price) combinations in HF calculation since LLTV is protocol-controlled while price should stay widely fuzzed
    /// @dev Should help fuzzer find valid HF scenarios
    /// @param colEntropy The entropy of the collateral token
    /// @param loanEntropy The entropy of the loan token
    function morpho_createMarket_clamped(uint8 colEntropy, uint8 loanEntropy) public {
        address[] memory allAssets = _getAssets();
        address collateralToken = allAssets[colEntropy % allAssets.length];
        address loanToken = allAssets[loanEntropy % allAssets.length];          

        MarketParams memory clampedParams = MarketParams({
            loanToken: loanToken,
            collateralToken: collateralToken,
            oracle: address(mockOracle),
            irm: address(mockIRM),
            lltv: currentLltv
        });
        
        morpho_createMarket(clampedParams);

        _addMarket(marketParams);
    }

    /// @dev Hardcoded empty data for liquidation (no callback triggered)
    /// @dev Clamped `borrower` with `indexActor` (so it not only do self-liquidation)
    /// @dev indexActor is uint8 as the actors is bounded in our setup
    function morpho_liquidate_clamped(uint256 seizedAssets, uint256 repaidShares) public {
       // max - colaltearlToLiqudiate so that we guild the liquidation to == max of balance but not foruce it to be max as it can pass belowign max
       morpho_liquidate(currentActor, seizedAssets, repaidShares, "");
    }

    /// @dev Clamped `borrower` and `assets` amount
    /// @dev indexActor is uint8 as the actors is bounded in our setup
    function morpho_liquidate_clamped_byShares(uint256 repaidShares) public {
        morpho_liquidate(currentActor, 0, repaidShares, "");
    }

    /// @dev Clamped `borrower` and `shares` amount
    /// @dev indexActor is uint8 as the actors is bounded in our setup
    function morpho_liquidate_clamped_byAssets(uint256 seizedAssets) public {
        morpho_liquidate(currentActor, seizedAssets, 0, "");
    }

    /// @dev Hardcoded empty data for liquidation (no callback triggered)
    /// @dev Use currentActor as onBehalf (set by fuzzer via switch)
    function morpho_repay_clamped(uint256 assets, uint256 shares) public {
        morpho_repay(assets, shares, currentActor, "");
    }

    /// @dev Clamped `onBehalf` and `assets` amount
    function morpho_repay_clamped_byShares(uint256 shares, address receiver) public {
        morpho_repay(0, shares, currentActor, "");
    }

    /// @dev Clamped `onBehalf` and `shares` amount
    function morpho_repay_clamped_byAssets(uint256 assets, address receiver) public {
        morpho_repay(assets, 0, currentActor, "");
    }

    /// @dev Hardcoded empty data for liquidation (no callback triggered)
    /// @dev Use currentActor as onBehalf (set by fuzzer via switch)
    function morpho_supply_clamped(uint256 assets, uint256 shares) public {
        morpho_supply(assets, shares, currentActor, "");
    }

    /// @dev Clamped `onBehalf` and `assets` amount
    function morpho_supply_clamped_byShares(uint256 shares, address receiver) public {
        morpho_supply(0, shares, currentActor, "");
    }

    /// @dev Clamped `onBehalf` and `shares` amount
    function morpho_supply_clamped_byAssets(uint256 assets, address receiver) public {
        morpho_supply(assets, 0, currentActor, "");
    }

    /// @dev Hardcoded empty data for liquidation (no callback triggered)
    /// @dev Use currentActor as onBehalf (set by fuzzer via switch)
    function morpho_supplyCollateral_clamped(uint256 assets) public {
        morpho_supplyCollateral(assets, currentActor, "");
    }

    /// @dev Use currentActor as onBehalf (set by fuzzer via switch)
    function morpho_withdraw_clamped(uint256 assets, uint256 shares, address receiver) public {
        morpho_withdraw(assets, shares, currentActor, receiver);
    }

    /// @dev Clamped `onBehalf` and `assets` amount
    function morpho_withdraw_clamped_byShares(uint256 shares, address receiver) public {
        morpho_withdraw(0, shares, currentActor, receiver);
    }

    /// @dev Clamped `onBehalf` and `shares` amount
    function morpho_withdraw_clamped_byAssets(uint256 assets, address receiver) public {
        morpho_withdraw(assets, 0, currentActor, receiver);
    }

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
    }

    function morpho_supplyCollateral(uint256 assets, address onBehalf, bytes memory data) public asActor {
        morpho.supplyCollateral(marketParams, assets, onBehalf, data);
        
        canarySupplyCollateral = true;
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