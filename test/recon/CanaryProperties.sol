// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {CanaryStorage} from "./CanaryStorage.sol";
import {Asserts} from "@chimera/Asserts.sol";

abstract contract CanaryProperties is CanaryStorage, Asserts {
    function canary_morpho_borrow() public {
        if (CANARY_ENABLED) {
            t(!canaryBorrow, "morpho_borrow called");
        }
    }

    function canary_morpho_borrowSelf() public {
        if (CANARY_ENABLED) {
            t(!canaryBorrowSelf, "morpho_borrow Self called");
        }
    }

    function canary_morpho_borrowOnBehalf() public {
        if (CANARY_ENABLED) {
            t(!canaryBorrowOnBehalf, "morpho_borrow OnBehalf called");
        }
    }

    function canary_morpho_createMarket() public {
        if (CANARY_ENABLED) {
            t(!canaryCreateMarket, "morpho_createMarket called");
        }
    }
    
    function canary_morpho_liquidate() public {
        if (CANARY_ENABLED) {
            t(!canaryLiquidate, "morpho_liquidate called");
        }
    }
    
    function canary_morpho_liquidateSelf() public {
        if (CANARY_ENABLED) {
            t(!canaryLiquidateSelf, "morpho_liquidate Self called");
        }
    }
    
    function canary_morpho_liquidateBorrower() public {
        if (CANARY_ENABLED) {
            t(!canaryLiquidateBorrower, "morpho_liquidate Borrower called");
        }
    }
    
    function canary_morpho_liquidateBadDebt() public {
        if (CANARY_ENABLED) {
            t(!canaryLiquidateBadDebt, "morpho_liquidate Baddebt called");
        }
    }
    
    function canary_morpho_repay() public {
        if (CANARY_ENABLED) {
            t(!canaryRepay, "morpho_repay called");
        }
    }
    
    function canary_morpho_repaySelf() public {
        if (CANARY_ENABLED) {
            t(!canaryRepaySelf, "morpho_repay Self called");
        }
    }
    
    function canary_morpho_repayOnBehalf() public {
        if (CANARY_ENABLED) {
            t(!canaryRepayOnBehalf, "morpho_repay OnBehalf called");
        }
    }
    
    /// @dev Check if morpho_supply has successful call
    function canary_morpho_supply() public {
        if (CANARY_ENABLED) {
            t(!canarySupply, "morpho_supply called");
        }
    }

    function canary_morpho_supplySelf() public {
        if (CANARY_ENABLED) {
            t(!canarySupplySelf, "morpho_supply Self called");
        }
    }
    
    function canary_morpho_supplyOnBehalf() public {
        if (CANARY_ENABLED) {
            t(!canarySupplyOnBehalf, "morpho_supply OnBehalf called");
        }
    }
    
    function canary_morpho_supplyCollateral() public {
        if (CANARY_ENABLED) {
            t(!canarySupplyCollateral, "morpho_supply Collateral called");
        }
    }
    
    function canary_morpho_supplyCollateralSelf() public {
        if (CANARY_ENABLED) {
            t(!canarySupplyCollateralSelf, "morpho_supplyCollateral Self called");
        }
    }
    
    function canary_morpho_supplyCollateralOnBehalf() public {
        if (CANARY_ENABLED) {
            t(!canarySupplyCollateralOnBehalf, "morpho_supplyCollateral OnBehalf called");
        }
    }
    
    function canary_morpho_withdraw() public {
        if (CANARY_ENABLED) {
            t(!canaryWithdraw, "morpho_withdraw called");
        }
    }
    
    function canary_morpho_withdrawSelf() public {
        if (CANARY_ENABLED) {
            t(!canaryWithdrawSelf, "morpho_withdraw Self called");
        }
    }
    
    function canary_morpho_withdrawOnBehalf() public {
        if (CANARY_ENABLED) {
            t(!canaryWithdrawOnBehalf, "morpho_withdraw OnBehalf called");
        }
    }
    
    function canary_morpho_withdrawCollateral() public {
        if (CANARY_ENABLED) {
            t(!canaryWithdrawCollateral, "morpho_withdrawCollateral called");
        }
    }
    
    function canary_morpho_withdrawCollateralSelf() public {
        if (CANARY_ENABLED) {
            t(!canaryWithdrawCollateralSelf, "morpho_withdrawCollateral Self called");
        }
    }
    
    function canary_morpho_withdrawCollateralOnBehalf() public {
        if (CANARY_ENABLED) {
            t(!canaryWithdrawCollateralOnBehalf, "morpho_withdrawCollateral OnBehalf called");
        }
    }
}
