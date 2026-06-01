// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Setup} from "./Setup.sol";

import {Market, MarketParams, Id} from "src/interfaces/IMorpho.sol";
import {MarketParamsLib} from "src/libraries/MarketParamsLib.sol";

import {SharesMathLib} from "src/libraries/SharesMathLib.sol";
abstract contract BeforeAfter is Setup {
    using MarketParamsLib for MarketParams;
    using SharesMathLib for uint256;

    struct Vars {
        // Market states
        mapping(bytes32 marketId => Market state) marketStates;
        mapping(bytes32 marketId => uint256 supplyShares) totalSupplyShares;
        mapping(bytes32 marketId => uint256 borrowShares) totalBorrowShares;
        mapping(bytes32 marketId => uint256 collateral) totalCollateralAssets;

        mapping(bytes32 marketId => uint256 maxWithdrawAssets) marketMaxWithdrawAssets;
        mapping(bytes32 marketId => uint256 debtAssets) totalDebtAssets;

        mapping(bytes32 marketId => uint256 interest) totalInterest;
        mapping(bytes32 marketId => uint256 badDebt) totalBadDebt;

        mapping(bytes32 marketId => bool userHealthy) allUserHealthy;

        // User states
        mapping(bytes32 marketId => mapping(address user => uint256 supplyShares)) userSupplyShares;
        mapping(bytes32 marketId => mapping(address user => uint256 borrowShares)) userBorrowShares;
        mapping(bytes32 marketId => mapping(address user => uint256 collateral)) userCollateralAssets;

        mapping(bytes32 marketId => mapping(address user => uint256 maxWithdrawAssets)) userMaxWithdrawAssets;
        mapping(bytes32 marketId => mapping(address user => uint256 debtAssets)) userDebtAssets;
        mapping(bytes32 marketId => mapping(address user => bool healthy)) userHealthy;

    }

    Vars internal _before;
    Vars internal _after;

    modifier updateGhosts {
        __before();
        _;
        __after();
    }


    function __before() internal {
        __before(_getActor());

    }

    function __after() internal {
        __after(_getActor());
    }

    modifier updateGhostsFor(address onBehalfOf) {
        __before(onBehalfOf);
        _;
        __after(onBehalfOf);
    }


    function __before(address onBehalfOf) internal {
        __snapshot(_before, onBehalfOf);

    }

    function __after(address onBehalfOf) internal {
        __snapshot(_after, onBehalfOf);
    }


    function __snapshot(Vars storage vars, address user) internal {
        bytes32 currentMarketId = Id.unwrap(marketParams.id());

        // Market states
        (uint128 totalSupplyAssets, uint128 totalSupplyShares, uint128 totalBorrowAssets, uint128 totalBorrowShares, uint128 lastUpdate, uint256 fee) = morpho.market(marketParams.id());
        vars.marketStates[currentMarketId] = Market(totalSupplyAssets, totalSupplyShares, totalBorrowAssets, totalBorrowShares, lastUpdate, uint128(fee));
        vars.totalSupplyShares[currentMarketId] = _sumSupplySharesForMarket(currentMarketId);
        vars.totalBorrowShares[currentMarketId] = _sumBorrowSharesForMarket(currentMarketId);
        vars.totalCollateralAssets[currentMarketId] = _sumCollateralForMarket(currentMarketId);
        vars.marketMaxWithdrawAssets[currentMarketId] = _sumMaxWithdrawAssets(currentMarketId);
        vars.totalDebtAssets[currentMarketId] = _sumDebtAssets(currentMarketId);

        vars.totalInterest[currentMarketId] = morpho.get_test_ghostTotalInterest(Id.wrap(currentMarketId));
        vars.totalBadDebt[currentMarketId] = morpho.get_test_ghostTotalBadDebt(Id.wrap(currentMarketId));

        vars.allUserHealthy[currentMarketId] = _allUserHealthy(marketParams);

        // User states
        (uint256 supplyShares, uint128 borrowShares, uint128 collateral) = morpho.position(Id.wrap(currentMarketId), user);
        vars.userSupplyShares[currentMarketId][user] = supplyShares;
        vars.userBorrowShares[currentMarketId][user] = borrowShares;
        vars.userCollateralAssets[currentMarketId][user] = collateral;
        vars.userMaxWithdrawAssets[currentMarketId][user] = _maxWithdrawAssets(currentMarketId, user);
        vars.userDebtAssets[currentMarketId][user] = _debtAssets(currentMarketId, user);
        vars.userHealthy[currentMarketId][user] = morpho.isHealthy(marketParams, user);

    }

    function _sumSupplySharesForMarket(bytes32 marketId) internal returns (uint256) {
        address[] memory actors = _getActors();

        uint256 sum_all_users_SupplyShares;
        for (uint256 i = 0; i < actors.length; i++) {
            (uint256 supplyShares,,) = morpho.position(Id.wrap(marketId), actors[i]);
            sum_all_users_SupplyShares += supplyShares;
        }

        return sum_all_users_SupplyShares;
    }

    function _sumBorrowSharesForMarket(bytes32 marketId) internal returns (uint256) {
        address[] memory actors = _getActors();

        uint256 sum_all_users_BorrowShares;
        for (uint256 i = 0; i < actors.length; i++) {
            (,uint256 borrowShares,) = morpho.position(Id.wrap(marketId), actors[i]);
            sum_all_users_BorrowShares += borrowShares;
        }

        return sum_all_users_BorrowShares;
    }

    function _sumCollateralForMarket(bytes32 marketId) internal returns (uint256) {
        address[] memory actors = _getActors();

        uint256 sum_all_users_Collateral;
        for (uint256 i = 0; i < actors.length; i++) {
            (,,uint256 collateral) = morpho.position(Id.wrap(marketId), actors[i]);
            sum_all_users_Collateral += collateral;
        }

        return sum_all_users_Collateral;
    }

    function _maxWithdrawAssets(bytes32 marketId, address user) internal returns (uint256) {
        (uint256 supplyShares,,) = morpho.position(Id.wrap(marketId), user);
        (uint128 market_totalSupplyAssets,uint128 market_totalSupplyShares,,,,) = morpho.market(Id.wrap(marketId));

        return supplyShares.toAssetsDown(market_totalSupplyAssets, market_totalSupplyShares);
    }

    function _debtAssets(bytes32 marketId, address user) internal returns (uint256) {
        (,uint256 borrowShares,) = morpho.position(Id.wrap(marketId), user);
        (,,uint128 market_totalBorrowAssets,uint128 market_totalBorrowShares,,) = morpho.market(Id.wrap(marketId));

        return borrowShares.toAssetsUp(market_totalBorrowAssets, market_totalBorrowShares);
    }

    function _sumMaxWithdrawAssets(bytes32 marketId) internal returns (uint256) {
        address[] memory actors = _getActors();
        (
            uint128 market_totalSupplyAssets,
            uint128 market_totalSupplyShares,
            ,
            ,
            ,
        ) = morpho.market(Id.wrap(marketId));

        uint256 sum_all_users_maxWithdrawAssets;
        for (uint256 i = 0; i < actors.length; i++) {
            sum_all_users_maxWithdrawAssets += _maxWithdrawAssets(marketId, actors[i]);
        }

        return sum_all_users_maxWithdrawAssets;
    }

    function _sumDebtAssets(bytes32 marketId) internal returns (uint256) {
        address[] memory actors = _getActors();

        uint256 sum_all_users_repayableBorrow;
        for (uint256 i = 0; i < actors.length; i++) {
            sum_all_users_repayableBorrow += _debtAssets(marketId, actors[i]);
        }

        return sum_all_users_repayableBorrow;
    }

    function _allUserHealthy(MarketParams memory market) internal returns (bool) {
        address[] memory actors = _getActors();

        bool isAllUserHealthy = true;
        for (uint256 i = 0; i < actors.length; i++) {
            isAllUserHealthy = isAllUserHealthy && morpho.isHealthy(market, actors[i]);
        }

        return isAllUserHealthy;
    }
}
