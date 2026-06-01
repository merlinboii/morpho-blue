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
import {MarketParamsLib} from "src/libraries/MarketParamsLib.sol";

abstract contract MorphoTargets is
    BaseTargetFunctions,
    Properties
{
    using MarketParamsLib for MarketParams;

    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    //////////// CLAMPED FUNCTIONS ////////////

    /// @dev Clamped function for morpho_createMarket using assets from AssetManager and governance-approved LLTVs
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

        _addMarket(clampedParams);
    }

    /// @dev Hardcoded empty data for liquidation (no callback triggered)
    function morpho_supply_clamped(uint256 assets, uint256 shares, uint256 onBehalfEntropy) public {
        address onBehalf = _getActors()[onBehalfEntropy % _getActors().length];
        morpho_supply(assets, shares, onBehalf, "");
    }

    function morpho_withdraw_clamped(uint256 assets, uint256 shares, uint256 onBehalfEntropy) public {
        address onBehalf = _getActors()[onBehalfEntropy % _getActors().length];
        morpho_withdraw(assets, shares, onBehalf, onBehalf);
    }


    /// @dev Clamped withdraw that leaves some/none supply shares in the position
    /// @dev Useful for testing partial withdrawals without fully draining the position (0 = fully drain)
    function morpho_withdraw_leaveSupplyShares_clamped(uint256 leaveSupplyShares, uint256 onBehalfEntropy, address receiver) public {
        address onBehalf = _getActors()[onBehalfEntropy % _getActors().length];

        (uint256 maxSupplyShares,,) = morpho.position(marketParams.id(), onBehalf);
        leaveSupplyShares %= (maxSupplyShares + 1);
        uint256 actualWithdraw = maxSupplyShares - leaveSupplyShares;

        morpho_withdraw(0, actualWithdraw, onBehalf, receiver);
    }

    /// @dev Clamped `onBehalf`
    /// @notice The fuzzer should find both self and onBehalf scenarios with this function, which it requies the selected onBehalf to authorize the actor beforehand
    function morpho_borrow_clamped(uint256 assets, uint256 shares, uint256 onBehalfEntropy, address receiver) public {
        address onBehalf = _getActors()[onBehalfEntropy % _getActors().length];
        morpho_borrow(assets, shares, onBehalf, receiver);
    }

    /// @dev Hardcoded empty data for liquidation (no callback triggered)
    function morpho_repay_clamped(uint256 assets, uint256 shares, uint256 onBehalfEntropy) public {
        address onBehalf = _getActors()[onBehalfEntropy % _getActors().length];
        
        morpho_repay(assets, shares, onBehalf, "");
    }

    /// @dev Hardcoded empty data for liquidation (no callback triggered)
    function morpho_repay_leaveBorrowShares_clamped(uint256 leaveBorrowShares, uint256 onBehalfEntropy) public {
        address onBehalf = _getActors()[onBehalfEntropy % _getActors().length];
        
        (,uint256 maxBorrowShares,) = morpho.position(marketParams.id(), onBehalf);
        leaveBorrowShares %= (maxBorrowShares + 1);
        uint256 actualRepay = maxBorrowShares - leaveBorrowShares;

        morpho_repay(actualRepay, 0, onBehalf, "");
    }

    /// @dev Hardcoded empty data for liquidation (no callback triggered)
    function morpho_liquidate_clamped(uint256 borrowerEntropy, uint256 seizedAssets, uint256 repaidShares) public {
        address borrower = _getActors()[borrowerEntropy % _getActors().length];
        morpho_liquidate(borrower, seizedAssets, repaidShares, "");
    }

    /// @dev Hardcoded empty data for liquidation (no callback triggered)
    function morpho_liquidate_leaveCollateralAssets_clamped(uint256 borrowerEntropy, uint256 leaveCollateralAssets) public {
        address borrower = _getActors()[borrowerEntropy % _getActors().length];

        (,,uint256 maxCollateral) = morpho.position(marketParams.id(), borrower);
        leaveCollateralAssets %= (maxCollateral + 1);
        uint256 actualSeizedAssets = maxCollateral - leaveCollateralAssets;
        
        morpho_liquidate(borrower, actualSeizedAssets, 0, "");
    }

    /// @dev Hardcoded empty data for liquidation (no callback triggered)
    function morpho_supplyCollateral_clamped(uint256 assets, uint256 onBehalfEntropy) public {
        address onBehalf = _getActors()[onBehalfEntropy % _getActors().length];
        morpho_supplyCollateral(assets, onBehalf, "");
    }

    /// @dev Hardcoded empty data for liquidation (no callback triggered)
    function morpho_withdrawCollateral_clamped(uint256 assets, uint256 onBehalfEntropy, address receiver) public {
        address onBehalf = _getActors()[onBehalfEntropy % _getActors().length];
        morpho_withdrawCollateral(assets, onBehalf, receiver);
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function morpho_accrueInterest() public updateGhosts() asActor {
        (
            uint128 before__market_totalSupplyAssets,
            ,
            uint128 before__market_totalBorrowAssets,
            uint128 before__market_totalBorrowShares,
            ,
        ) = morpho.market(marketParams.id());
        
        morpho.accrueInterest(marketParams);
        
        (
            uint128 after__market_totalSupplyAssets,
            ,
            uint128 after__market_totalBorrowAssets,
            uint128 after__market_totalBorrowShares,
            ,
        ) = morpho.market(marketParams.id());

        // Inlined properties:
        /// @dev total supply assets and total borrow assets should be the same or increase after accruing interest
        gte(
            after__market_totalSupplyAssets,
            before__market_totalSupplyAssets,
            "accrue interest: total supply assets decreased"
        );

        gte(
            after__market_totalBorrowAssets,
            before__market_totalBorrowAssets,
            "accrue interest: total borrow assets decreased"
        );

        /// @dev The increase should apply symmetrically to supply and borrow side
        eq(
            after__market_totalSupplyAssets - before__market_totalSupplyAssets,
            after__market_totalBorrowAssets - before__market_totalBorrowAssets,
            "accrue interest: supply asset delta != borrow asset delta"
        );

        eq(
            after__market_totalBorrowShares,
            before__market_totalBorrowShares,
            "accrue interest: total borrow shares changed"
        );
    }

    function morpho_borrow(uint256 assets, uint256 shares, address onBehalf, address receiver) public updateGhostsFor(onBehalf) asActor {
        (,uint128 before__user_borrowShares,) = morpho.position(marketParams.id(), onBehalf);
        
        morpho.borrow(marketParams, assets, shares, onBehalf, receiver);

        (,uint128 after__user_borrowShares,) = morpho.position(marketParams.id(), onBehalf);
        
        canaryBorrow = true;

        if (_getActor() == onBehalf) {
            canaryBorrowSelf = true;
        } else {
            canaryBorrowOnBehalf = true;
        }

        // Inlined properties:

        /// @dev If borrow shares, the *exact* input shares should be assigned to the borrower
        if (shares > 0) {
            eq(
                after__user_borrowShares,
                before__user_borrowShares + shares,
                "borrow by shares: borrower share delta != input shares"
            );
        }

        /// @dev If borrow by assets, the borrower must receive some borrow shares
        if (assets > 0) {
            gt(
                after__user_borrowShares, 
                before__user_borrowShares, 
                "borrow by assets: should increase user's borrow shares"
            );
        }
    }

    /// @dev Create Morpho market and record the market
    /// @dev Does not add to MarketManager; only clamped operable markets should be rotated by switchMarket.
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

    function morpho_liquidate(address borrower, uint256 seizedAssets, uint256 repaidShares, bytes memory data) public updateGhostsFor(borrower) asActor {
        morpho.liquidate(marketParams, borrower, seizedAssets, repaidShares, data);
        (,,uint256 maxCollateral) = morpho.position(marketParams.id(), borrower);

        canaryLiquidate = true;

        if (_getActor() == borrower) {
            canaryLiquidateSelf = true;
        } else {
            canaryLiquidateBorrower = true;
        }
        // Bad debt occurs when borrower's collateral is fully seized but debt remains
        if (maxCollateral == 0){
            canaryLiquidateBadDebt = true;
        }

    }

    function morpho_repay(uint256 assets, uint256 shares, address onBehalf, bytes memory data) public updateGhostsFor(onBehalf) asActor {
        (,uint256 before__user_borrowShares,) = morpho.position(marketParams.id(), onBehalf);
        morpho.repay(marketParams, assets, shares, onBehalf, data);
        (,uint256 after__user_borrowShares,) = morpho.position(marketParams.id(), onBehalf);
        
        canaryRepay = true;
        
        if (_getActor() == onBehalf) {
            canaryRepaySelf = true;
        } else {
            canaryRepayOnBehalf = true;
        }

        // Inlined properties:
        /// @dev Repay-by-shares should burn exactly the input shares from the borrower.
        if (shares > 0) {
            eq(
                after__user_borrowShares,
                before__user_borrowShares - shares,
                "repay by shares: borrower share delta != input shares"
            );
        }

        /// @dev Repay-by-assets should burn borrow shares from the borrower.
        if (assets > 0) {
            lt(
                after__user_borrowShares,
                before__user_borrowShares,
                "repay by assets: borrower borrow shares did not decrease"
            );
        }
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

    /// @dev Hardcoded fee recipient to one of the test actors for testing purposes
    function morpho_setFeeRecipient(address) public asActor {
        morpho.setFeeRecipient(_getActor());
    }

    function morpho_setOwner(address newOwner) public asActor {
        morpho.setOwner(newOwner);
    }

    /// @dev Internal only so all fuzz entrypoints route through clamped handlers
    /// @dev This keeps `onBehalf` inside the tracked actor set, which is required for aggregate accounting properties that sum over `_getActors()`
    function morpho_supply(uint256 assets, uint256 shares, address onBehalf, bytes memory data) internal updateGhostsFor(onBehalf) asActor {
        (uint256 before__user_supplyShares,,) = morpho.position(marketParams.id(), onBehalf);
        morpho.supply(marketParams, assets, shares, onBehalf, data);
        (uint256 after__user_supplyShares,,) = morpho.position(marketParams.id(), onBehalf);

        canarySupply = true;
        
        if (_getActor() == onBehalf) {
            canarySupplySelf = true;
        } else {
            canarySupplyOnBehalf = true;
        }

        // Inlined properties:
        /// @dev If supply by shares, the *exact* input shares should be received by the supplier (unless fee recipient, who can receive more shares than input)
        if (shares > 0) {
            if (onBehalf == morpho.feeRecipient()) {
                gte(
                    after__user_supplyShares, 
                    before__user_supplyShares + shares, 
                    "supply by shares: fee recipient share delta < input shares"
                );
            } else {
                eq(
                    after__user_supplyShares, 
                    before__user_supplyShares+ shares, 
                    "supply by shares: supplier share delta != input shares"
                );

            }
        }
        /// @dev If supply by assets, the user must receive some supply shares
        if (assets > 0 && onBehalf != morpho.feeRecipient()) {
            gt(
                after__user_supplyShares, 
                before__user_supplyShares, 
                "supply by assets: nonzero assets minted zero shares"
            );
        }
    }

    /// @dev Internal only so all fuzz entrypoints route through clamped handlers
    /// @dev This keeps `onBehalf` inside the tracked actor set, which is required for aggregate accounting properties that sum over `_getActors()`
    function morpho_supplyCollateral(uint256 assets, address onBehalf, bytes memory data) internal updateGhostsFor(onBehalf) asActor {
        (,,uint256 before__user_collateral) = morpho.position(marketParams.id(), onBehalf);

        morpho.supplyCollateral(marketParams, assets, onBehalf, data);
        (,,uint256 after__user_collateral) = morpho.position(marketParams.id(), onBehalf);

        canarySupplyCollateral = true;
        
        if (_getActor() == onBehalf) {
            canarySupplyCollateralSelf = true;
        } else {
            canarySupplyCollateralOnBehalf = true;
        }

        // Inlined properties:
        eq(
            after__user_collateral,
            before__user_collateral + assets,
            "supplyCollateral: users' collateral delta != input assets "
        );
    }

    function morpho_withdraw(uint256 assets, uint256 shares, address onBehalf, address receiver) public updateGhostsFor(onBehalf) asActor {
        (uint256 before__user_supplyShares,,) = morpho.position(marketParams.id(), onBehalf);
        morpho.withdraw(marketParams, assets, shares, onBehalf, receiver);
        (uint256 after__user_supplyShares,,) = morpho.position(marketParams.id(), onBehalf);

        canaryWithdraw = true;
        
        if (_getActor() == onBehalf) {
            canaryWithdrawSelf = true;
        } else {
            canaryWithdrawOnBehalf = true;
        }

        /// @dev If withdraw by shares, the exact input shares should be burned unless fee shares offset the burn.
        if (shares > 0) {
            if (onBehalf == morpho.feeRecipient()) {
                if (before__user_supplyShares > after__user_supplyShares) {
                    lte(
                        after__user_supplyShares,
                        before__user_supplyShares - shares,
                        "withdraw by shares: fee recipient net share decrease exceeds input shares"
                    );
                }
            } else {
                eq(
                    after__user_supplyShares, 
                    before__user_supplyShares - shares, 
                    "withdraw by shares: supplier share delta != input shares"
                );

            }
        }
        /// @dev If withdraw by assets, the user's supply shares should decrease.
        if (assets > 0 && onBehalf != morpho.feeRecipient()) {
            lt(
                after__user_supplyShares, 
                before__user_supplyShares, 
                "withdraw by assets: supplier shares did not decrease"
            );
        }
    }

    function morpho_withdrawCollateral(uint256 assets, address onBehalf, address receiver) public updateGhostsFor(onBehalf) asActor {
        (,,uint256 before__user_collateral) = morpho.position(marketParams.id(), onBehalf);
        morpho.withdrawCollateral(marketParams, assets, onBehalf, receiver);
        (,,uint256 after__user_collateral) = morpho.position(marketParams.id(), onBehalf);

        canaryWithdrawCollateral = true;
        
        if (_getActor() == onBehalf) {
            canaryWithdrawCollateralSelf = true;
        } else {
            canaryWithdrawCollateralOnBehalf = true;
        }

        // Inlined properties:
        eq(
            after__user_collateral,
            before__user_collateral - assets,
            "withdrawCollateral: users' collateral delta != input assets "
        );
    }
}
