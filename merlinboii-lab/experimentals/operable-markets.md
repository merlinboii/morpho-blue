# Operable market

## Problem

Even if we expose both clamped and unclamped `createMarket` handlers, the fuzzer can still fail to operate on useful markets.

A market is **operable** when our harness can actually drive actions on it: `supply`, `withdraw`, `supplyCollateral`, `withdrawCollateral`, `borrow`, `repay`, `liquidate` and `flashloan`

A market can be successfully created by `Morpho.createMarket()` but still be non-operable for our fuzzing env.

```solidity
struct MarketParams {
    address loanToken;
    address collateralToken;
    address oracle;
    address irm;
    uint256 lltv;
}
```

For example:

- `loanToken` may not be one of our mock ERC20 tokens
- `collateralToken` may not be one of our mock ERC20 tokens
- `oracle` may not be our mock oracle
- `irm` may not be our mock IRM

We only expose our mockERC20s, mockOracle, and mockIRM to the fuzzer. So if a market is created with random addresses, we can't mint/approve tokens or update oracle prices for it - making it useless for further operations.

If we track all created markets in one list, the fuzzer keeps switching to these dead-end markets and wastes time reverting.
        
## Current approach: 
```solidity
function morpho_createMarket_clamped(uint8 collatIndex, uint8 loanIndex) public {
    address collateralToken = _getTokenAt(uint256(collatIndex));
    address loanToken = _getTokenAt(uint256(loanIndex));

    MarketParams memory clampedParams = MarketParams({
        loanToken: loanToken,
        collateralToken: collateralToken,
        oracle: address(mockOracle),
        irm: address(mockIRM),
        lltv: currentLltv
    });
    
    morpho_createMarket(clampedParams);
}

function morpho_createMarket(MarketParams memory marketParams) public asActor {
    morpho.createMarket(marketParams);
    canaryCreateMarket = true;

    /// @dev morpho.createMarket() already block duplicate market creation, assert below again just in case
    t(_addMarket(marketParams), "duplicate market");
}
```

The issue is that `_addMarket(marketParams)` registers every successfully created market into the same market list.

This means the market list can contain:

- clamped markets that the harness can operate on
- unclamped markets that Morpho accepted, but the harness cannot operate on

So later handlers may rotate into a non-operable market and waste exploration.

## Solution (hope it works)

Track two separate market sets:

1. **`_createdMarkets`** - every market that `Morpho.createMarket()` accepted
2. **`_operableMarkets`** - only markets our harness can actually do stuff with

Normal handlers pick from `_operableMarkets`. If we want to stress test weird edge cases, we can optionally pick from `_createdMarkets`.

## Operable rule

For this scaffold, a market is considered **operable** if the harness can meaningfully drive normal Morpho actions on it.

A market is operable if:

- `loanToken` is one of our mock ERC20 tokens
- `collateralToken` is one of our mock ERC20 tokens
- `oracle` is our `mockOracle`
- `irm` is our `mockIRM`

We do **not** filter by `lltv` in the operable-market rule.

If the fuzzer can enable the LLTV and `Morpho.createMarket()` succeeds, then we consider the market operable from the LLTV perspective.

However, `lltv` still matters for reaching deeper paths. It's used in `_isHealthy` with oracle price:
- `lltv` range: `[0, WAD]` → large space
- `price` range: `[0, uint256.max]` → large space

Many `(lltv, price)` combinations will fail the health check, making borrow/liquidate unreachable. We handle this separately by clamping to pre-enabled LLTVs via `setup_switchCurrentLltv`, not by filtering operable markets.

## Rationale

The purpose of `operableMarkets` is not to classify every real-world-valid Morpho market. It is to classify which markets our current fuzzing environment can actually operate on.

For example, if `loanToken` or `collateralToken` is an arbitrary address, the market may be accepted by Morpho, but our handlers cannot mint balances, approve tokens, or transfer those assets. So the market is not useful for normal supply, borrow, repay, withdraw, or liquidation flows.

The same applies to the oracle and IRM. Even if another oracle or IRM could be valid in a real deployment, our current scaffold only knows how to control `mockOracle` and `mockIRM`.

So we have:

- `_marketIds` tracks every market accepted by Morpho
- `_operableMarketIds` tracks only markets that this harness can drive

## Future work

In the future, we can expand the operable-market rule instead of hardcoding only the current mocks:

- If `loanToken` has ERC20 functionality, add it to the fuzz token registry so handlers can mint, approve, and transfer it.
- If `collateralToken` has ERC20 functionality, add it to the fuzz token registry so handlers can mint, approve, and transfer it.
- If `oracle` implements the expected Oracle interface, add it to the supported oracle registry so handlers can control or read prices safely.
- If `irm` implements the expected IRM interface, add it to the supported IRM registry so handlers can use it safely.

This would let the harness operate on a wider set of markets while still avoiding random markets that the handlers cannot meaningfully drive.