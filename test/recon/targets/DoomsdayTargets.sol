// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import {MarketParams, Id} from "src/interfaces/IMorpho.sol";
import {MarketParamsLib} from "src/libraries/MarketParamsLib.sol";
import {MockERC20} from "lib/setup-helpers/src/MockERC20.sol";


abstract contract DoomsdayTargets is
    BaseTargetFunctions,
    Properties
{
    using MarketParamsLib for MarketParams;

    /// Makes a handler have no side effects
    /// The fuzzer will call this anyway, and because it reverts it will be removed from shrinking
    /// Replace the "withGhosts" with "stateless" to make the code clean
    modifier stateless() {
        _;
        revert("stateless");
    }

    ////////////////////// DOOMSDAY TARGETS //////////////////////

    function doomsday_close_all_positions_leave_zero_debt() public stateless {
        address[] memory actors = _getActors();
        MarketParams memory currentMarket = _getMarket();

        _doomsday_close_all_positions(currentMarket, actors);

        (,,uint128 market_totalBorrowAssets,uint128 market_totalBorrowShares,,) = morpho.market(Id.wrap(_getMarketId()));
        
        eq(market_totalBorrowShares, 0, "close all positions: borrow shares not zero");
        eq(market_totalBorrowAssets, 0, "close all positions: borrow assets not zero");    
    }

    function doomsday_noBorrow_allUsersCanWithdraw_loan() public stateless {
        address[] memory actors = _getActors();
        MarketParams memory currentMarket = _getMarket();

        _doomsday_close_all_positions(currentMarket, actors);
            
        for (uint256 i = 0; i < actors.length; i++) {
            address user = actors[i];

            vm.prank(user);
            morpho.setAuthorization(address(this), true);

            (uint256 user_supplyShares,,) = morpho.position(Id.wrap(_getMarketId()), user);

            if (user_supplyShares > 0) {
                try morpho.withdraw(currentMarket, 0, user_supplyShares, user, user) {
                    // withdraw succeeded
                } catch {
                    t(false, "if no borrow position, user should be able to withdraw their supply loan");
                }
            }
        }
    }

    function doomsday_noBorrow_allUsersCanWithdraw_collateral() public stateless {
        address[] memory actors = _getActors();
        MarketParams memory currentMarket = _getMarket();

        _doomsday_close_all_positions(currentMarket, actors);

        for (uint256 i = 0; i < actors.length; i++) {
            address user = actors[i];
            vm.prank(user);
            morpho.setAuthorization(address(this), true);

            (,,uint256 collateral) = morpho.position(Id.wrap(_getMarketId()), user);

            if (collateral > 0) {
                try morpho.withdrawCollateral(currentMarket, collateral, user, user) {
                    // withdraw succeeded
                } catch {
                    t(false, "if no borrow position, user should be able to withdraw their collateral");
                }
            }
        }
    }

    function doomsday_liquidation_preservesOtherMarketsHealth() public stateless {
        bytes32 targetMarketId = _getMarketId();
        MarketParams memory targetMarket = _getMarket();
        bytes32[] memory marketIds = _getMarketIds();
        bool[] memory otherMarketHealthyBefore = new bool[](marketIds.length);
        address[] memory actors = _getActors();

        for (uint256 i; i < marketIds.length; i++) {
            if (marketIds[i] == targetMarketId) continue;
            otherMarketHealthyBefore[i] = _allUserHealthy(_getMarketParams(marketIds[i]));
        }

        MockERC20(targetMarket.loanToken).mint(address(this), type(uint88).max);
        MockERC20(targetMarket.loanToken).approve(address(morpho), type(uint256).max);

        bool liquidated;
        for (uint256 i; i < actors.length; i++) {
            address borrower = actors[i];
            (,uint256 borrowShares,) = morpho.position(targetMarket.id(), borrower);

            if (borrowShares == 0 || morpho.isHealthy(targetMarket, borrower)) continue;

            morpho.liquidate(targetMarket, borrower, 0, borrowShares, "");
        }

        for (uint256 i; i < marketIds.length; i++) {
            if (marketIds[i] == targetMarketId) continue;
            if (!otherMarketHealthyBefore[i]) continue;
            
            t(
                _allUserHealthy(_getMarketParams(marketIds[i])),
                "liquidation in one market made another market unhealthy"
            );
        }
    }

    function doomsday_supplyByAssetWithdrawShares(uint88 assets) public stateless {
        _doomsday_supplyWithdraw(assets, 0);
    }

    function doomsday_supplyBySharesWithdrawShares(uint88 shares) public stateless {
        _doomsday_supplyWithdraw(0, shares);
    }

    function doomsday_borrowByAssetRepayShares(uint88 assets) public stateless {
        _doomsday_borrowRepay(assets, 0);
    }

    function doomsday_borrowBySharesRepayShares(uint88 shares) public stateless {
        _doomsday_borrowRepay(0, shares);
    }



    ///////////////////// HELPER FUNCTIONS /////////////////////

    function _doomsday_close_all_positions(MarketParams memory market, address[] memory actors) internal {
        // mint to operator to ensure liquidations and repayments can succeed
        MockERC20(market.loanToken).mint(address(this), type(uint88).max);
        MockERC20(market.loanToken).approve(address(morpho), type(uint256).max);

        for (uint256 i = 0; i < actors.length; i++) {
            address user = actors[i];
            _doomsday_close_position(market, user);
        }
    }

    function _doomsday_close_position(MarketParams memory market, address user) internal {
        (,uint256 user_borrowShares,) = morpho.position(market.id(), user);
        bool user_isHealthy = morpho.isHealthy(market, user);

        if (user_borrowShares == 0) return;

        if (!user_isHealthy) {
            // liquidate the borrow position
            morpho.liquidate(market, user, 0, user_borrowShares, "");
        } else {
            // repay, close borrow position
            morpho.repay(market, 0, user_borrowShares, user, "");
        }
    }

    function _doomsday_supplyWithdraw(uint256 assets, uint256 shares) internal {
        /////// SET UP //////
        address user = _getActor();
        MarketParams memory currentMarket = _getMarket();
        Id id = currentMarket.id();

        vm.prank(user);
        MockERC20(currentMarket.loanToken).approve(address(morpho), type(uint256).max);

        /////// ACTION ///////
        uint256 user_tokenBalanceBefore = MockERC20(currentMarket.loanToken).balanceOf(user);

        (uint256 user_supplySharesBefore,,) = morpho.position(id, user);
        vm.prank(user);
        morpho.supply(currentMarket, assets, shares, user, "");
        (uint256 user_supplySharesAfter,,) = morpho.position(id, user);

        uint256 newSupplyShares = user_supplySharesAfter - user_supplySharesBefore;

        vm.prank(user);
        morpho.withdraw(currentMarket, 0, newSupplyShares, user, user);

        uint256 user_tokenBalanceAfter = MockERC20(currentMarket.loanToken).balanceOf(user);

        /////// ASSERTIONS ///////
        // no profit
        lte(
            user_tokenBalanceAfter,
            user_tokenBalanceBefore,
            "supply then withdraw immediately: make user profit"
        );

        // loss bounded
        uint256 LOSS_TOLERANCE = 2; // (?) 2 wei should be enough to cover rounding issues
        lte(
            user_tokenBalanceBefore - user_tokenBalanceAfter,
            LOSS_TOLERANCE,
            "supply then withdraw immediately: make user loss exceeds rounding tolerance"
        );
    }

    function _doomsday_borrowRepay(uint256 assets, uint256 shares) internal {
        /////// SET UP //////
        address user = _getActor();
        MarketParams memory currentMarket = _getMarket();
        Id id = currentMarket.id();

        vm.prank(user);
        MockERC20(currentMarket.loanToken).approve(address(morpho), type(uint256).max);

        morpho.accrueInterest(currentMarket);
        
        /////// ACTION ///////
        (, uint256 user_borrowSharesBefore,) = morpho.position(id, user);
        (,, uint128 market_totalBorrowAssetsBefore,,,) = morpho.market(id);

        morpho.borrow(currentMarket, assets, 0, user, user);
        (, uint256 user_borrowSharesAfterBorrow,) = morpho.position(id, user);

        uint256 newBorrowShares = user_borrowSharesAfterBorrow - user_borrowSharesBefore;

        vm.prank(user);
        morpho.repay(currentMarket, 0, newBorrowShares, user, "");

        (, uint256 user_borrowSharesAfter,) = morpho.position(id, user);
        (,, uint128 market_totalBorrowAssetsAfter,,,) = morpho.market(id);
        
        /////// ASSERTIONS ///////
        eq(
            user_borrowSharesAfter,
            user_borrowSharesBefore,
            "borrow asset then repay shares: user borrow shares not restored"
        );

        // Because repay by shares uses toAssetsUp, Morpho allows assets repaid to exceed totalBorrowAssets by 1.
        lte(
            market_totalBorrowAssetsAfter,
            uint256(market_totalBorrowAssetsBefore) + 1,
            "borrow asset then repay shares: total borrow assets increased beyond rounding"
        );
    }

}
