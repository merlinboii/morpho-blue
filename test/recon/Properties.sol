// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";

import {CanaryProperties} from "./CanaryProperties.sol";
import {MarketParams, Id} from "src/interfaces/IMorpho.sol";
import {MockERC20} from "lib/setup-helpers/src/MockERC20.sol";


abstract contract Properties is BeforeAfter, Asserts, CanaryProperties {
    /// @dev token.balanceOf(morpho) == SUM(market_i.totalSupplyAssets - market_i.totalBorrowAssets for markets using token as loanToken) + SUM(collateral held for markets using token as collateralToken) + donations
    function property_supplier_solvency() public {
        address[] memory assets = _getAssets();
        bytes32[] memory marketIds = _getMarketIds();

        for (uint256 a; a < assets.length; a++) {
            address token = assets[a];

            uint256 totalLoanSupplyAssets;
            uint256 totalLoanBorrowAssets;
            uint256 totalCollateralAssets;

            for (uint256 i; i < marketIds.length; i++) {
                MarketParams memory params = _getMarketParams(marketIds[i]);
                (uint128 market_totalSupplyAssets,, uint128 market_totalBorrowAssets,,,) = morpho.market(Id.wrap(marketIds[i]));

                if (params.loanToken == token) {
                    totalLoanSupplyAssets += market_totalSupplyAssets;
                    totalLoanBorrowAssets += market_totalBorrowAssets;
                }

                if (params.collateralToken == token) {
                    totalCollateralAssets += _sumCollateralForMarket(marketIds[i]);
                }
            }

            uint256 expectedAccountedBalance = totalLoanSupplyAssets + totalCollateralAssets - totalLoanBorrowAssets;

            uint256 actualBalance = MockERC20(token).balanceOf(address(morpho));

            t(
                actualBalance >= expectedAccountedBalance,
                "token balance below accounted loan liquidity + collateral"
            );
        }
    }

    ///@dev Property: cannot have borrow shares without collateral
    function property_no_borrowShares_without_collateral() public {
        bytes32[] memory marketIds = _getMarketIds();
        address[] memory actors = _getActors();

        // each user that have borrow shares > 0 should have collateral > 0
        for (uint256 i; i < actors.length; i++) {
            address target_user = actors[i];

            for(uint256 j; j < marketIds.length; j++) {

                (,uint256 user_borrowShares, uint256 user_collateral) = morpho.position(Id.wrap(marketIds[j]), target_user);
                
                bool hasBorrowShares = user_borrowShares > 0;
                bool hasCollateral = user_collateral > 0;

                // A borrower with debt shares must have collateral
                // The reverse is not required: users can supply collateral without borrowing
                t(!hasBorrowShares || hasCollateral, "user has borrow shares with zero collateral");
            }
        }
    }

    /// @dev Property: if market has no borrow shares, then interest should not accrue
    function property_no_borrow_no_interest_accrual() public {
        bytes32 currentMarketId = _getMarketId();
        // if no borrow shares before actions, interest should not accrue
        if (_before.totalBorrowShares[currentMarketId] == 0) {
            eq(
                _after.totalInterest[currentMarketId], _before.totalInterest[currentMarketId], 
                "market has no borrow shares but interest accrued"
            );
        }
    }

    /// @dev Property: interest should never decrease for a market
    function property_interest_not_decrease() public {
        bytes32 currentMarketId = _getMarketId();
        
        gte(
            _after.totalInterest[currentMarketId],
            _before.totalInterest[currentMarketId], 
            "total interest decreased"
        );
    }

    /// @dev Property: market.totalBorrowAssets should never exceed market.totalSupplyAssets
    function property_market_borrow_is_covered_by_supply() public {
        bytes32[] memory marketIds = _getMarketIds();

        for (uint256 i; i < marketIds.length; i++) {
            (uint128 market_totalSupplyAssets,, uint128 market_totalBorrowAssets,,,) = morpho.market(Id.wrap(marketIds[i]));

            t(
                market_totalBorrowAssets <= market_totalSupplyAssets,
                "market total borrow assets exceeds total supply assets, borrow is not fully covered by supply"
            );
        }
    }
    
    /// @dev Property: market.totalSupplyAssets should be sufficient to cover all user withdraw in the market
    function property_market_totalSupplyAssets_can_cover_user_maxWithdrawAssets() public {
        bytes32[] memory marketIds = _getMarketIds();


        for (uint256 i; i < marketIds.length; i++) {
            uint256 totalMaxWithdrawAssets = _sumMaxWithdrawAssets(marketIds[i]);
            (uint128 market_totalSupplyAssets,,,,,) = morpho.market(Id.wrap(marketIds[i]));

            t(
                totalMaxWithdrawAssets <= market_totalSupplyAssets,
                "market total max withdraw assets exceeds total supply assets, withdraw is not fully covered by supply"
            );
        }
    }

    /// @dev Property: market_i.totalSupplyShares == SUM(user_n.supplyShares in market_i)
    function property_market_total_supplyShares_match_sum_user_supplyShares() public {
        bytes32[] memory marketIds = _getMarketIds();

        for (uint256 i; i < marketIds.length; i++) {
            bytes32 target_marketId = marketIds[i];

            (,uint128 market_totalSupplyShares,,,,) = morpho.market(Id.wrap(target_marketId));
            uint256 sum_all_users_SupplyShares = _sumSupplySharesForMarket(target_marketId);

            eq(
                market_totalSupplyShares,
                sum_all_users_SupplyShares,
                "market totalSupplyShares != sum user supplyShares"
            );
        }
    }

    /// @dev Property: market_i.totalBorrowShares == SUM(user_n.borrowShares in market_i)
    function property_market_total_borrowShares_match_sum_user_borrowShares() public {
        bytes32[] memory marketIds = _getMarketIds();

        for (uint256 i; i < marketIds.length; i++) {
            bytes32 target_marketId = marketIds[i];

            (,,,uint128 market_totalBorrowShares,,) = morpho.market(Id.wrap(target_marketId));
            uint256 sum_all_users_BorrowShares = _sumBorrowSharesForMarket(target_marketId);

            eq(
                market_totalBorrowShares,
                sum_all_users_BorrowShares,
                "market totalBorrowShares != sum user borrowShares"
            );
        }
    }

    ///@dev Property: if market.totalBorrowShares > 0 then market.totalBorrowAssets > 0, and if market.totalBorrowShares == 0 then market.totalBorrowAssets == 0
    function property_market_borrowAssets_zero_iff_borrowShares_zero() public {
        bytes32[] memory marketIds = _getMarketIds();

        for (uint256 i; i < marketIds.length; i++) {
            Id id = Id.wrap(marketIds[i]);

            (,, uint128 market_totalBorrowAssets, uint128 market_totalBorrowShares,,) = morpho.market(id);

            t(
                (market_totalBorrowAssets == 0) == (market_totalBorrowShares == 0),
                "market has one-sided borrow accounting"
            );
        }
    }

    /// @follow-up property_market_supplyAssets_zero_iff_supplyShares_zero 🚸
}
