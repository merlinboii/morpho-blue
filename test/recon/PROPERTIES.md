# Properties
> Table inspired by: [@recon/superform-v2-periphery-scfuzzbench](https://github.com/Recon-Fuzz/superform-v2-periphery-scfuzzbench/blob/dev/test/recon/properties-table.md)

## Morpho
See [test/recon/CryticToFoundry.sol](./CryticToFoundry.sol) for reproductions of broken properties.

> ✅: implemented/passing | ❌: failing | 🚸: needs more investigation

### Global Properties
| ID | Property | Description | Implemented | Passes |
| --- | --- | --- | --- | --- |
| G-01 | `property_supplier_solvency` | For each tracked token, Morpho's balance must cover accounted loan liquidity plus tracked collateral: `balance >= SUM(totalSupplyAssets - totalBorrowAssets for loan markets) + SUM(collateral for collateral markets)`. Donations/untracked balances are allowed as surplus | ✅ |  |
| G-02 | `property_no_borrowShares_without_collateral` | A tracked user with borrow shares in a market must also have collateral in that market | ✅ |  |
| G-03 | `property_no_borrow_no_interest_accrual` | If the current market had no borrow shares before the tracked operation, cumulative interest for that market must not increase | ✅ |  |
| G-05 | `property_interest_not_decrease` | Cumulative tracked interest for the current market must be monotonic | ✅ |  |
| G-06 | `property_market_borrow_is_covered_by_supply` | For each market, `totalBorrowAssets <= totalSupplyAssets`. Catches internal market debt exceeding supplied loan accounting | ✅ |  |
| G-07 | `property_market_totalSupplyAssets_can_cover_user_maxWithdrawAssets` | For each market, the sum of tracked users' max withdraw assets must not exceed market `totalSupplyAssets` | ✅ |  |
| G-08 | `property_market_total_supplyShares_match_sum_user_supplyShares` | For each market, `totalSupplyShares == SUM(tracked user supplyShares)`. Covers the narrower current-market version | ✅ |  |
| G-09 | `property_market_total_borrowShares_match_sum_user_borrowShares` | For each market, `totalBorrowShares == SUM(tracked user borrowShares)`. Covers the narrower current-market version | ✅ |  |
| G-10 | `property_market_borrowAssets_zero_iff_borrowShares_zero` | For each market, `totalBorrowAssets == 0 <=> totalBorrowShares == 0`. Catches one-sided borrow accounting | ✅ | ❌ |

### Inlined Properties

| ID | Property | Description | Implemented | Passes |
| --- | --- | --- | --- | --- |
| I-01 | `morpho_accrueInterest` | `totalSupplyAssets` must not decrease | ✅ |  |
| I-02 | `morpho_accrueInterest` | `totalBorrowAssets` must not decrease | ✅ |  |
| I-03 | `morpho_accrueInterest` | Supply asset delta must equal borrow asset delta | ✅ |  |
| I-04 | `morpho_accrueInterest` | `totalBorrowShares` must not change | ✅ |  |
| I-05 | `morpho_supply` | Supply-by-shares to fee recipient must increase `onBehalf.supplyShares` by at least input shares | ✅ |  |
| I-06 | `morpho_supply` | Supply-by-shares to non-fee recipient must increase `onBehalf.supplyShares` exactly by input shares | ✅ |  |
| I-07 | `morpho_supply` | Supply-by-assets to non-fee recipient must increase `onBehalf.supplyShares` | ✅ |  |
| I-08 | `morpho_supplyCollateral` | Supplying collateral must increase `onBehalf.collateral` exactly by input assets | ✅ |  |
| I-09 | `morpho_withdraw` | Withdraw-by-shares from fee recipient must satisfy the fee-recipient net share bound | ✅ |  |
| I-10 | `morpho_withdraw` | Withdraw-by-shares from non-fee recipient must decrease `onBehalf.supplyShares` exactly by input shares | ✅ |  |
| I-11 | `morpho_withdraw` | Withdraw-by-assets from non-fee recipient must decrease `onBehalf.supplyShares` | ✅ |  |
| I-12 | `morpho_withdrawCollateral` | Withdrawing collateral must decrease `onBehalf.collateral` exactly by input assets | ✅ |  |
| I-13 | `morpho_borrow` | Borrow-by-shares must increase `onBehalf.borrowShares` exactly by input shares | ✅ |  |
| I-14 | `morpho_borrow` | Borrow-by-assets must increase `onBehalf.borrowShares` | ✅ |  |
| I-15 | `morpho_repay` | Repay-by-shares must decrease `onBehalf.borrowShares` exactly by input shares | ✅ |  |
| I-16 | `morpho_repay` | Repay-by-assets must decrease `onBehalf.borrowShares` | ✅ |  |
| I-17 | `shortcut_morpho_accrue_first_then_supply_byShares` | After explicit accrual, supply-by-shares must increase market `totalSupplyAssets` | ✅ |  |
| I-18 | `shortcut_morpho_accrue_first_then_supply_byAssets` | After explicit accrual, supply-by-assets must increase market `totalSupplyAssets` exactly by input assets | ✅ |  |
| I-19 | `shortcut_morpho_accrue_first_then_withdraw_byShares` | After explicit accrual, withdraw-by-shares must decrease market `totalSupplyAssets. | ✅ | 🚸 |
| I-20 | `shortcut_morpho_accrue_first_then_withdraw_byAssets` | After explicit accrual, withdraw-by-assets must decrease market `totalSupplyAssets` exactly by input assets | ✅ |  |
| I-21 | `shortcut_morpho_accrue_first_then_borrow_byShares` | After explicit accrual, borrow-by-shares must increase market `totalBorrowAssets` | ✅ | ❌ |
| I-22 | `shortcut_morpho_accrue_first_then_borrow_byAssets` | After explicit accrual, borrow-by-assets must increase market `totalBorrowAssets` exactly by input assets | ✅ |  |
| I-23 | `shortcut_morpho_accrue_first_then_repay_byShares` | After explicit accrual, repay-by-shares must decrease market `totalBorrowAssets` | ✅ | 🚸 |
| I-24 | `shortcut_morpho_accrue_first_then_repay_byShares` | After explicit accrual, repay-by-shares must not increase borrower repayable debt | ✅ |  |
| I-25 | `shortcut_morpho_accrue_first_then_repay_byShares` | After explicit accrual, repay-by-shares must not worsen borrower debt-per-collateral when debt and collateral remain | ✅ |  |
| I-26 | `shortcut_morpho_accrue_first_then_repay_byShares` | After explicit accrual, repay-by-shares must not make remaining borrow shares more expensive | ✅ |  |
| I-27 | `shortcut_morpho_accrue_first_then_repay_byAssets` | After explicit accrual, repay-by-assets must decrease market `totalBorrowAssets` exactly by input assets, bounded at zero | ✅ |  |
| I-28 | `shortcut_morpho_accrue_first_then_repay_byAssets` | After explicit accrual, repay-by-assets must not increase borrower repayable debt | ✅ |  |
| I-29 | `shortcut_morpho_accrue_first_then_repay_byAssets` | After explicit accrual, repay-by-assets must not worsen borrower debt-per-collateral when debt and collateral remain | ✅ |  |
| I-30 | `shortcut_morpho_accrue_first_then_repay_byAssets` | After explicit accrual, repay-by-assets must not make remaining borrow shares more expensive | ✅ |  |
| I-31 | `shortcut_morpho_accrue_first_then_liquidate_byShares` | Liquidation by repaid shares must not increase borrower repayable debt | ✅ |  |
| I-32 | `shortcut_morpho_accrue_first_then_liquidate_byShares` | Liquidation by repaid shares must not increase borrower collateral | ✅ |  |
| I-33 | `shortcut_morpho_accrue_first_then_liquidate_byShares` | If liquidation by repaid shares leaves borrower collateral at zero, borrower repayable debt must be zero | ✅ |  |
| I-34 | `shortcut_morpho_accrue_first_then_liquidate_byShares` | Liquidation by repaid shares must not worsen borrower debt-per-collateral when debt and collateral remain | ✅ |  |
| I-35 | `shortcut_morpho_accrue_first_then_liquidate_byShares` | Liquidation by repaid shares must not make remaining borrow shares more expensive | ✅ |  |
| I-36 | `shortcut_morpho_accrue_first_then_liquidate_byAssets` | Liquidation by seized assets must not increase borrower repayable debt | ✅ |  |
| I-37 | `shortcut_morpho_accrue_first_then_liquidate_byAssets` | Liquidation by seized assets must not increase borrower collateral | ✅ |  |
| I-38 | `shortcut_morpho_accrue_first_then_liquidate_byAssets` | If liquidation by seized assets leaves borrower collateral at zero, borrower repayable debt must be zero | ✅ |  |
| I-39 | `shortcut_morpho_accrue_first_then_liquidate_byAssets` | Liquidation by seized assets must not worsen borrower debt-per-collateral when debt and collateral remain | ✅ |  |
| I-40 | `shortcut_morpho_accrue_first_then_liquidate_byAssets` | Liquidation by seized assets must not make remaining borrow shares more expensive. | ✅ | 🚸 |

### Scenario Properties
| ID | Property | Description | Implemented | Passes |
| --- | --- | --- | --- | --- |
| S-01 | `doomsday_close_all_positions_leave_zero_debt` | Recovery: close each tracked borrow position by liquidation or repayment, then require market borrow shares and borrow assets to be zero. | ✅ |  |
| S-02 | `doomsday_noBorrow_allUsersCanWithdraw_loan` | Liveness/solvency: after closing borrow positions, all tracked suppliers with supply shares should be able to withdraw loan-token supply. | ✅ | 🚸 |
| S-03 | `doomsday_noBorrow_allUsersCanWithdraw_collateral` | Liveness/solvency: after closing borrow positions, all tracked users with collateral should be able to withdraw collateral. | ✅ | 🚸 |
| S-04 | `doomsday_liquidation_preservesOtherMarketsHealth` | Cross-market isolation: liquidating an unhealthy borrower in the current market must not make tracked users unhealthy in other markets that were healthy before. | ✅ |  |
| S-05 | `doomsday_supplyByAssetWithdrawShares` | Round-trip supply: supply by assets, withdraw the minted shares, require no profit and loss bounded by tolerance. | ✅ | 🚸 |
| S-06 | `doomsday_supplyBySharesWithdrawShares` | Round-trip supply: supply by shares, withdraw the minted shares, require no profit and loss bounded by tolerance. | ✅ |  |
| S-07 | `doomsday_borrowByAssetRepayShares` | Round-trip debt: borrow by assets, repay the new borrow shares, require borrower shares restored and market borrow assets not increased beyond rounding. | ✅ |  |
| S-08 | `doomsday_borrowBySharesRepayShares` | Round-trip debt: borrow by shares, repay the new borrow shares, require borrower shares restored and market borrow assets not increased beyond rounding. | ✅ |  |

----

## Todo:
- Reduce redundant inline properties / refactor inline properties to global properties
 - How to move specific properties to global properties? Some require checks for specific actions: add supply, remove supply
 - Some properties need to measure pure supply accounting, without being affected by interest accrual (`_accrueInterest`)
- Properties for market isolation (idea: one market should not affect other market)
- Should global properties loop through all markets -> users, or is it fine to check the current market only?
