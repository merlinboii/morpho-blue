// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";

import "forge-std/console2.sol";

import {Test} from "forge-std/Test.sol";
import {TargetFunctions} from "./TargetFunctions.sol";


// forge test --match-contract CryticToFoundry -vv
contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();

        targetContract(address(this));
    }

    // forge test --match-test test_crytic -vvv
    function test_crytic() public {
        // TODO: add failing property tests here for debugging
    }

    //////////// CANARY TESTS ////////////

// forge test --match-test test_canary_morpho_withdrawOnBehalf_pxtw -vvv
    function test_canary_morpho_withdrawOnBehalf_pxtw() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_setAuthorization(0x0000000000000000000000000000000000000034,true);
    
        switchActor(2);
    
        morpho_supply_clamped(1,0,0);
    
        morpho_withdraw_leaveSupplyShares_clamped(0,0,0x00000000000000000000000000000000DeaDBeef);
    
        canary_morpho_withdrawOnBehalf();
    
    }

// forge test --match-test test_canary_morpho_supply_phu0 -vvv
    function test_canary_morpho_supply_phu0() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supply(0,1,0x00000000000000000000000000000000DeaDBeef,hex"");
    
        canary_morpho_supply();
    
    }

// forge test --match-test test_canary_morpho_liquidateSelf_zdjx -vvv
    function test_canary_morpho_liquidateSelf_zdjx() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        oracleMock_setPrice(2000113448602429266854106114141956312);
    
        morpho_borrow_clamped(0,1,0,0x00000000000000000000000000000000DeaDBeef);
    
        oracleMock_setPrice(0);
    
        morpho_liquidate_leaveCollateralAssets_clamped(0,0);
    
        canary_morpho_liquidateSelf();
    
    }

// forge test --match-test test_canary_morpho_supplyOnBehalf_ip66 -vvv
    function test_canary_morpho_supplyOnBehalf_ip66() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supply(0,1,0x00000000000000000000000000000000DeaDBeef,hex"");
    
        canary_morpho_supplyOnBehalf();
    
    }

// forge test --match-test test_canary_morpho_borrowOnBehalf_dyjz -vvv
    function test_canary_morpho_borrowOnBehalf_dyjz() public {
    
        morpho_setAuthorization(0x0000000000000000000000000000000000000034,true);
    
        switchActor(2);
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        oracleMock_setPrice(2000064040375058251861441959564599224);
    
        morpho_borrow_clamped(0,1,0,0x00000000000000000000000000000000DeaDBeef);
    
        canary_morpho_borrowOnBehalf();
    
    }

// forge test --match-test test_canary_morpho_withdrawSelf_wesz -vvv
    function test_canary_morpho_withdrawSelf_wesz() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supply_clamped(1,0,0);
    
        morpho_withdraw_leaveSupplyShares_clamped(0,0,0x00000000000000000000000000000000DeaDBeef);
    
        canary_morpho_withdrawSelf();
    
    }

// forge test --match-test test_canary_morpho_borrowSelf_su5c -vvv
    function test_canary_morpho_borrowSelf_su5c() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        oracleMock_setPrice(2000121619934935599831571214215929138);
    
        morpho_borrow_clamped(0,1,0,0x00000000000000000000000000000000DeaDBeef);
    
        canary_morpho_borrowSelf();
    
    }

// forge test --match-test test_canary_morpho_withdrawCollateralOnBehalf_s8te -vvv
    function test_canary_morpho_withdrawCollateralOnBehalf_s8te() public {
    
        morpho_createMarket_clamped(0,0);
    
        morpho_setAuthorization(0x0000000000000000000000000000000000000034,true);
    
        switchActor(2);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        morpho_withdrawCollateral(1,0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496,0x00000000000000000000000000000000DeaDBeef);
    
        canary_morpho_withdrawCollateralOnBehalf();
    
    }

// forge test --match-test test_canary_morpho_repay_zibu -vvv
    function test_canary_morpho_repay_zibu() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        oracleMock_setPrice(2000138670221804858635157882413072872);
    
        morpho_borrow_clamped(0,1,0,0x00000000000000000000000000000000DeaDBeef);
    
        morpho_repay_clamped(0,1,0);
    
        canary_morpho_repay();
    
    }

// forge test --match-test test_canary_morpho_repayOnBehalf_thpw -vvv
    function test_canary_morpho_repayOnBehalf_thpw() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        oracleMock_setPrice(2000138670221804858635157882413072872);
    
        morpho_borrow_clamped(0,1,0,0x00000000000000000000000000000000DeaDBeef);
    
        switchActor(1);
    
        morpho_repay_clamped(0,1,0);
    
        canary_morpho_repayOnBehalf();
    
    }

// forge test --match-test test_canary_morpho_liquidateBorrower_3el3 -vvv
    function test_canary_morpho_liquidateBorrower_3el3() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        oracleMock_setPrice(2000138670221804858635157882413072872);
    
        morpho_borrow_clamped(0,1,0,0x00000000000000000000000000000000DeaDBeef);
    
        oracleMock_setPrice(0);
    
        switchActor(1);
    
        morpho_liquidate_leaveCollateralAssets_clamped(0,0);
    
        canary_morpho_liquidateBorrower();
    
    }

// forge test --match-test test_canary_morpho_liquidate_16iz -vvv
    function test_canary_morpho_liquidate_16iz() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        oracleMock_setPrice(2000113448602429266854106114141956312);
    
        morpho_borrow_clamped(0,1,0,0x00000000000000000000000000000000DeaDBeef);
    
        oracleMock_setPrice(0);
    
        morpho_liquidate_leaveCollateralAssets_clamped(0,0);
    
        canary_morpho_liquidate();
    
    }

// forge test --match-test test_canary_morpho_supplyCollateralOnBehalf_q32j -vvv
    function test_canary_morpho_supplyCollateralOnBehalf_q32j() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,1);
    
        canary_morpho_supplyCollateralOnBehalf();
    
    }

// forge test --match-test test_canary_morpho_withdrawCollateralSelf_zs8n -vvv
    function test_canary_morpho_withdrawCollateralSelf_zs8n() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        morpho_withdrawCollateral(1,0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496,0x00000000000000000000000000000000DeaDBeef);
    
        canary_morpho_withdrawCollateralSelf();
    
    }

// forge test --match-test test_canary_morpho_repaySelf_48zz -vvv
    function test_canary_morpho_repaySelf_48zz() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        oracleMock_setPrice(2000138670221804858635157882413072872);
    
        morpho_borrow_clamped(0,1,0,0x00000000000000000000000000000000DeaDBeef);
    
        morpho_repay_clamped(0,1,0);
    
        canary_morpho_repaySelf();
    
    }

// forge test --match-test test_canary_morpho_liquidateBadDebt_fphk -vvv
    function test_canary_morpho_liquidateBadDebt_fphk() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        oracleMock_setPrice(2000060585887356962685137384371184972);
    
        morpho_borrow_clamped(0,1,0,0x00000000000000000000000000000000DeaDBeef);
    
        oracleMock_setPrice(0);
    
        morpho_liquidate_leaveCollateralAssets_clamped(0,0);
    
        canary_morpho_liquidateBadDebt();
    
    }

// forge test --match-test test_canary_morpho_createMarket_jb62 -vvv
    function test_canary_morpho_createMarket_jb62() public {
    
        morpho_createMarket_clamped(0,0);
    
        canary_morpho_createMarket();
    
    }

// forge test --match-test test_canary_morpho_withdraw_01vw -vvv
    function test_canary_morpho_withdraw_01vw() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supply_clamped(1,0,0);
    
        morpho_withdraw_leaveSupplyShares_clamped(0,0,0x00000000000000000000000000000000DeaDBeef);
    
        canary_morpho_withdraw();
    
    }

// forge test --match-test test_canary_morpho_supplySelf_jl1e -vvv
    function test_canary_morpho_supplySelf_jl1e() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supply_clamped(0,1,0);
    
        canary_morpho_supplySelf();
    
    }

// forge test --match-test test_canary_morpho_supplyCollateral_k8o9 -vvv
    function test_canary_morpho_supplyCollateral_k8o9() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        canary_morpho_supplyCollateral();
    
    }

// forge test --match-test test_canary_morpho_withdrawCollateral_qhnp -vvv
    function test_canary_morpho_withdrawCollateral_qhnp() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        morpho_withdrawCollateral(1,0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496,0x00000000000000000000000000000000DeaDBeef);
    
        canary_morpho_withdrawCollateral();
    
    }

// forge test --match-test test_canary_morpho_supplyCollateralSelf_rj8p -vvv
    function test_canary_morpho_supplyCollateralSelf_rj8p() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        canary_morpho_supplyCollateralSelf();
    
    }

// forge test --match-test test_canary_morpho_borrow_dmcm -vvv
    function test_canary_morpho_borrow_dmcm() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        oracleMock_setPrice(2000138670221804858635157882413072872);
    
        morpho_borrow_clamped(0,1,0,0x00000000000000000000000000000000DeaDBeef);
    
        canary_morpho_borrow();
    
    }

    //////////////////// Properties ////////////////////

// forge test --match-test test_property_market_borrowAssets_zero_iff_borrowShares_zero_9xm3 -vvv
    function test_property_market_borrowAssets_zero_iff_borrowShares_zero_9xm3() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        oracleMock_setPrice(2000138670221804858635157882413072872);
    
        morpho_borrow_clamped(0,1,0,0x00000000000000000000000000000000DeaDBeef);

        //@audit result: Market({ totalSupplyAssets: 0, totalSupplyShares: 0, totalBorrowAssets: 0, totalBorrowShares: 1, lastUpdate: 1, fee: 0 })
        property_market_borrowAssets_zero_iff_borrowShares_zero();
    
    }

// 🚸 forge test --match-test test_doomsday_noBorrow_allUsersCanWithdraw_loan_jg7f -vvv
    function test_doomsday_noBorrow_allUsersCanWithdraw_loan_jg7f() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supply_clamped(1,0,0);
    
        mockIRM_setFixedRate(61414216387259957501412125360490);
    
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
        //@audit seems caused by overflow in `_accrueInterest()`
        doomsday_noBorrow_allUsersCanWithdraw_loan();
    
    }

// 🚸 forge test --match-test test_doomsday_noBorrow_allUsersCanWithdraw_collateral_vc49 -vvv
    function test_doomsday_noBorrow_allUsersCanWithdraw_collateral_vc49() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
        mockIRM_setFixedRate(61438198585342590510108567423565);
        //@audit seems caused by overflow in `_accrueInterest()`
        doomsday_noBorrow_allUsersCanWithdraw_collateral();
    
    }

// forge test --match-test test_shortcut_morpho_accrue_first_then_borrow_byShares_qwli -vvv
    function test_shortcut_morpho_accrue_first_then_borrow_byShares_qwli() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        oracleMock_setPrice(2000138670221804858635157882413072872);

        //@audit result: Market({ totalSupplyAssets: 0, totalSupplyShares: 0, totalBorrowAssets: 0, totalBorrowShares: 1, lastUpdate: 1, fee: 0 })
        shortcut_morpho_accrue_first_then_borrow_byShares(1,0,0x00000000000000000000000000000000DeaDBeef);
    
    }

// 🚸 forge test --match-test test_shortcut_morpho_accrue_first_then_repay_byShares_bszo -vvv
    function test_shortcut_morpho_accrue_first_then_repay_byShares_bszo() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        oracleMock_setPrice(2000128600597676267434175840638218406);
    
        morpho_borrow_clamped(0,1,0,0x00000000000000000000000000000000DeaDBeef);
        
        shortcut_morpho_accrue_first_then_repay_byShares(1,0);
    
    }

// 🚸 forge test --match-test test_shortcut_morpho_accrue_first_then_liquidate_byAssets_28ib -vvv
    function test_shortcut_morpho_accrue_first_then_liquidate_byAssets_28ib() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        oracleMock_setPrice(2000072179590754583942233864462067728);
    
        morpho_borrow_clamped(0,1,0,0x00000000000000000000000000000000DeaDBeef);
    
        oracleMock_setPrice(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        shortcut_morpho_accrue_first_then_liquidate_byAssets(1,46521550604090151335);
    
    }

// 🚸 forge test --match-test test_shortcut_morpho_accrue_first_then_withdraw_byShares_fa69 -vvv
    function test_shortcut_morpho_accrue_first_then_withdraw_byShares_fa69() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supply_clamped(1,0,0);
    
        shortcut_morpho_accrue_first_then_withdraw_byShares(1,0);
    
    }

// 🚸 forge test --match-test test_doomsday_supplyByAssetWithdrawShares_fg04 -vvv
    function test_doomsday_supplyByAssetWithdrawShares_fg04() public {
    
        morpho_createMarket_clamped(0,0);
    
        switchMarket(0);
    
        morpho_supplyCollateral_clamped(1,0);
    
        oracleMock_setPrice(2000138670221804858635157882413072872);
    
        morpho_supply_clamped(1,0,0);
    
        morpho_borrow_clamped(1,0,473554153303315079422746268311904616565055785,0x00000000000000000000000000000000DeaDBeef);
    
        mockIRM_setFixedRate(2421143598876493);
    
        vm.warp(block.timestamp + 128025);
    
        vm.roll(block.number + 1);
        
        //@audit might bc low `LOSS_TOLERANCE` 
        doomsday_supplyByAssetWithdrawShares(5);
    
    }
}