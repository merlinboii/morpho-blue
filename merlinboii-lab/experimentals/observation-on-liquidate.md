# Observation on Liquidation path

## Current handler

- Base target: 
```solidity
function morpho_liquidate(address borrower, uint256 seizedAssets, uint256 repaidShares, bytes memory data) public asActor {
    morpho.liquidate(marketParams, borrower, seizedAssets, repaidShares, data);

    canaryLiquidate = true;
}
```

- Clamped versions:
```solidity
/// @dev Hardcoded empty data for liquidation (no callback triggered)
/// @dev Use currentActor as borrower (set by fuzzer via switch)
function morpho_liquidate_clamped(uint256 seizedAssets, uint256 repaidShares, bytes memory data) public {
    morpho_liquidate(currentActor, seizedAssets, repaidShares, "");
}

/// @dev Clamped `onBehalf` and `assets` amount
function morpho_liquidate_byShares(uint256 shares, address receiver) public {
    morpho_liquidate(currentActor, 0, shares, "");
}

/// @dev Clamped `onBehalf` and `shares` amount
function morpho_liquidate_byAssets(uint256 assets, address receiver) public {
    morpho_liquidate(currentActor, assets, 0, "");
}
```

As the base target `morpho_liquidate()` is applied `asActor` which will prank as `currentActor`.
So for our clamped versions we passing the `currentActor` as the `borrower` parameter, we only expose the **self-liquidation** scenario.
