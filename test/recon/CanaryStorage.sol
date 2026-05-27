// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

abstract contract CanaryStorage {
    // CONFIG
    bool constant CANARY_ENABLED = false;

    bool canaryBorrow;
    bool canaryCreateMarket;
    bool canaryLiquidate;
    bool canaryRepay;
    bool canarySupply;
    bool canarySupplyCollateral;
    bool canaryWithdraw;
    bool canaryWithdrawCollateral;

    bool canarySupplySelf;
    bool canarySupplyOnBehalf;
    
    bool canaryWithdrawSelf;
    bool canaryWithdrawOnBehalf;
    
    bool canaryBorrowSelf;
    bool canaryBorrowOnBehalf;

    bool canaryRepaySelf;
    bool canaryRepayOnBehalf;
    
    bool canarySupplyCollateralSelf;
    bool canarySupplyCollateralOnBehalf;
    
    bool canaryWithdrawCollateralSelf;
    bool canaryWithdrawCollateralOnBehalf;
    
    bool canaryLiquidateSelf;
    bool canaryLiquidateBorrower;
    bool canaryLiquidateBadDebt;
}