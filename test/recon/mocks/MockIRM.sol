pragma solidity ^0.8.0;

import {IIrm, MarketParams, Market} from "src/interfaces/IIrm.sol";

/// @notice This contract is used to mock the IRM contract
/// @dev The IRM is a fixed rate interest rate model
/// @dev Using fixed rate for ALL markets for simplicity in testing
contract MockIRM is IIrm {

    uint256 public fixedRate;
    
    /// @dev set the fixed rate
    function setFixedRate(uint256 _fixedRate) external {
        fixedRate = _fixedRate;
    }
    
    function borrowRateView(MarketParams memory marketParams, Market memory market) public view returns (uint256){
        return fixedRate;
    }

    function borrowRate(MarketParams memory marketParams, Market memory market) external view returns (uint256){
        return borrowRateView(marketParams, market);
    }


    
}