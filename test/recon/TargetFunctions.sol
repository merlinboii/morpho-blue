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
import {MarketParams, Id} from "src/interfaces/IMorpho.sol";
import {MarketParamsLib} from "src/libraries/MarketParamsLib.sol";

import {MockERC20} from "@recon/MockERC20.sol";

abstract contract TargetFunctions is
    AdminTargets,
    DoomsdayTargets,
    ManagersTargets,
    MockIRMTargets,
    MorphoTargets,
    OracleMockTargets
{
    using MarketParamsLib for MarketParams;

    modifier accrueInterest() {
        morpho_accrueInterest();
        _;
    }

     /// === TARGET FUNCTION SETUP === ///
     /// @dev If you need to set up any state for your target functions, add those handlers here. They will be called before the fuzzer calls the target function.
     /// @dev You can also add custom modifiers if you want to reuse some setup across multiple target functions.
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// === SET UP ENV HANDLERS === /// 

    function setup_switchCurrentLltv(uint8 index) public {
        _switchCurrentLltv(uint256(index));
    }

    function asset_donateToMorpho(uint88 assets) public updateGhosts() asActor {
        MockERC20(_getAsset()).mint(address(morpho), assets);
    }

    function shortcut_morpho_accrue_first_then_supply_byShares(uint256 shares, uint256 onBehalfEntropy) public accrueInterest {
        bytes32 marketId = _getMarketId();
        morpho_supply_clamped(0, shares, onBehalfEntropy);
        
        gt(
            _after.marketStates[marketId].totalSupplyAssets, 
            _before.marketStates[marketId].totalSupplyAssets, 
            "supply by shares: minted shares without increasing supply assets"
        );
    }

    function shortcut_morpho_accrue_first_then_supply_byAssets(uint256 assets, uint256 onBehalfEntropy) public accrueInterest {
        bytes32 marketId = _getMarketId();
        morpho_supply_clamped(assets, 0, onBehalfEntropy);

        eq(
            _after.marketStates[marketId].totalSupplyAssets, 
            _before.marketStates[marketId].totalSupplyAssets + assets, 
            "supply by assets: supply asset delta != input assets"
        );
    }

    function shortcut_morpho_accrue_first_then_withdraw_byShares(uint256 shares, uint256 onBehalfEntropy) public accrueInterest {
        bytes32 marketId = _getMarketId();
        morpho_withdraw_clamped(0, shares, onBehalfEntropy);
        
        lt(
            _after.marketStates[marketId].totalSupplyAssets, 
            _before.marketStates[marketId].totalSupplyAssets, 
            "withdraw by shares: burned shares without decreasing supply assets"
        );
    }

    function shortcut_morpho_accrue_first_then_withdraw_byAssets(uint256 assets, uint256 onBehalfEntropy) public accrueInterest {
        bytes32 marketId = _getMarketId();
        morpho_withdraw_clamped(assets, 0, onBehalfEntropy);
        
        eq(
            _after.marketStates[marketId].totalSupplyAssets, 
            _before.marketStates[marketId].totalSupplyAssets - assets, 
            "withdraw by assets: supply asset delta != input assets"
        );
    }


    function shortcut_morpho_accrue_first_then_borrow_byShares(uint256 shares, uint256 onBehalfEntropy, address receiver) public accrueInterest{
        bytes32 marketId = _getMarketId();
        morpho_borrow_clamped(0, shares, onBehalfEntropy, receiver);

        gt(
            _after.marketStates[marketId].totalBorrowAssets,
            _before.marketStates[marketId].totalBorrowAssets, 
            "borrow by shares: minted borrow shares without increasing borrow assets"
        );
    }

    function shortcut_morpho_accrue_first_then_borrow_byAssets(uint256 assets, uint256 onBehalfEntropy, address receiver) public accrueInterest {
        bytes32 marketId = _getMarketId();
        morpho_borrow_clamped(assets, 0, onBehalfEntropy, receiver);

        eq(
            _after.marketStates[marketId].totalBorrowAssets,
            _before.marketStates[marketId].totalBorrowAssets + assets,
            "borrow by assets: borrow asset delta != input assets"
        );
    }

    function shortcut_morpho_accrue_first_then_repay_byShares(uint256 shares, uint256 onBehalfEntropy) public accrueInterest {
        bytes32 marketId = _getMarketId();
        address onBehalf = _getActors()[onBehalfEntropy % _getActors().length];
        morpho_repay(0, shares, onBehalf, "");

        lt(
            _after.marketStates[marketId].totalBorrowAssets,
            _before.marketStates[marketId].totalBorrowAssets, 
            "repay by shares: burned borrow shares without decreasing borrow assets"
        );

        /// @dev After explicit accrual, repayment should not worsen the borrower's repayable debt.
        lte(
            _after.userDebtAssets[marketId][onBehalf],
            _before.userDebtAssets[marketId][onBehalf],
            "repay by shares: borrower repayable debt increased"
        );

        _assert_position_must_not_go_worse(marketId, onBehalf);
        _assert_borrow_pps_must_not_go_worse(marketId);

    }

    function shortcut_morpho_accrue_first_then_repay_byAssets(uint256 assets, uint256 onBehalfEntropy) public accrueInterest {
        bytes32 marketId = _getMarketId();
        address onBehalf = _getActors()[onBehalfEntropy % _getActors().length];
        morpho_repay(assets, 0, onBehalf, "");

        eq(
            _after.marketStates[marketId].totalBorrowAssets,
            assets >= _before.marketStates[marketId].totalBorrowAssets 
                ? 0 
                : _before.marketStates[marketId].totalBorrowAssets - assets,
            "repay by assets: total borrow assets delta mismatch"
        );

        /// @dev After explicit accrual, repayment should not worsen the borrower's repayable debt.
        lte(
            _after.userDebtAssets[marketId][onBehalf],
            _before.userDebtAssets[marketId][onBehalf],
            "repay by assets: borrower repayable debt increased"
        );

        _assert_position_must_not_go_worse(marketId, onBehalf);
        _assert_borrow_pps_must_not_go_worse(marketId);
    }

    function shortcut_morpho_accrue_first_then_liquidate_byShares(uint256 repaidShares, uint256 borrowerEntropy) public accrueInterest {
        bytes32 marketId = _getMarketId();
        address borrower = _getActors()[borrowerEntropy % _getActors().length];
        morpho_liquidate(borrower, 0, repaidShares, "");

        /// @dev Liquidation should not increase the borrower's repayable debt.
        lte(
            _after.userDebtAssets[marketId][borrower],
            _before.userDebtAssets[marketId][borrower],
            "liquidate: borrower repayable debt increased"
        );

        /// @dev Liquidation should not add collateral to the borrower.
        lte(
            _after.userCollateralAssets[marketId][borrower],
            _before.userCollateralAssets[marketId][borrower],
            "liquidate: borrower collateral increased"
        );

        /// @dev If all collateral is seized, bad-debt cleanup should leave no repayable debt.
        if (_after.userCollateralAssets[marketId][borrower] == 0) {
            eq(
                _after.userDebtAssets[marketId][borrower],
                0,
                "liquidate: zero collateral should leave zero repayable debt"
            );
        }

        _assert_position_must_not_go_worse(marketId, borrower);
        _assert_borrow_pps_must_not_go_worse(marketId);
    }

    function shortcut_morpho_accrue_first_then_liquidate_byAssets(uint256 seizedAssets, uint256 borrowerEntropy) public accrueInterest {
        bytes32 marketId = _getMarketId();
        address borrower = _getActors()[borrowerEntropy % _getActors().length];
        morpho_liquidate(borrower, seizedAssets, 0, "");

        /// @dev Liquidation should not increase the borrower's repayable debt.
        lte(
            _after.userDebtAssets[marketId][borrower],
            _before.userDebtAssets[marketId][borrower],
            "liquidate: borrower repayable debt increased"
        );

        /// @dev Liquidation should not add collateral to the borrower.
        lte(
            _after.userCollateralAssets[marketId][borrower],
            _before.userCollateralAssets[marketId][borrower],
            "liquidate: borrower collateral increased"
        );

        /// @dev If all collateral is seized, bad-debt cleanup should leave no repayable debt.
        if (_after.userCollateralAssets[marketId][borrower] == 0) {
            eq(
                _after.userDebtAssets[marketId][borrower],
                0,
                "liquidate: zero collateral should leave zero repayable debt"
            );
        }

        _assert_position_must_not_go_worse(marketId, borrower);
        _assert_borrow_pps_must_not_go_worse(marketId);
    }

    /////////////////// ASSERTION HELPERS ///////////////////

    function _assert_position_must_not_go_worse(bytes32 marketId, address user) internal {
        /// @dev If the borrower still has debt and collateral, debt/collateral should not worsen.
        /// after_debt/after_collateral <= before_debt/before_collateral  
        /// after_debt * before_collateral <= before_debt * after_collateral
        if (
            _after.userDebtAssets[marketId][user] > 0 
            && _after.userCollateralAssets[marketId][user] > 0 
            && _before.userCollateralAssets[marketId][user] > 0) 
        {
            lte(
                _after.userDebtAssets[marketId][user] * _before.userCollateralAssets[marketId][user],
                _before.userDebtAssets[marketId][user] * _after.userCollateralAssets[marketId][user],
                "borrower debt per collateral worsened"
            );
        }
    }

    function _assert_borrow_pps_must_not_go_worse(bytes32 marketId) internal {
        /// @dev Borrow price per share should not worsen for remaining borrowers.
        /// after_borrowAssets/after_borrowShares <= before_borrowAssets/before_borrowShares (with applying virtual 1e6 shares and 1 asset)
        /// after_borrowAssets * (before_borrowShares + 1e6) <= before_borrowAssets * (after_borrowShares + 1e6)
        
        lte(
            (uint256(_after.marketStates[marketId].totalBorrowAssets) + 1) * (uint256(_before.marketStates[marketId].totalSupplyShares) + 1e6),
            (uint256(_before.marketStates[marketId].totalBorrowAssets) + 1) * (uint256(_after.marketStates[marketId].totalSupplyShares) + 1e6),
            "liquidate: borrow price per share worsened after liquidation"
        );
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///
}
