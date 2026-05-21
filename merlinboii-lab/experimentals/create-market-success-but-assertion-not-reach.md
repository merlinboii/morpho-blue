## morpho_createMarket reached but reverted

Precondition: already have clamped version with valid values

## problem

`_addMarket()` never reached but `morpho.createMarket()` looks fully covered?

### converage
`Morpho.sol`:
```text
 150 | *   |     function createMarket(MarketParams memory marketParams) external {
 151 | *   |         Id id = marketParams.id();
 152 | *   |         require(isIrmEnabled[marketParams.irm], ErrorsLib.IRM_NOT_ENABLED);
 153 | *   |         require(isLltvEnabled[marketParams.lltv], ErrorsLib.LLTV_NOT_ENABLED);
 154 | *   |         require(market[id].lastUpdate == 0, ErrorsLib.MARKET_ALREADY_CREATED);
 155 |     | 
 156 |     |         // Safe "unchecked" cast.
 157 | *   |         market[id].lastUpdate = uint128(block.timestamp);
 158 | *   |         idToMarketParams[id] = marketParams;
 159 |     | 
 160 | *   |         emit EventsLib.CreateMarket(id, marketParams);
 161 |     | 
 162 |     |         // Call to initialize the IRM in case it is stateful.
 163 | *   |         if (marketParams.irm != address(0)) IIrm(marketParams.irm).borrowRate(marketParams, market[id]);
 164 |     |     }
```

`MorphoTargets.sol`:
```text
 35 | *   |     function morpho_createMarket(MarketParams memory marketParams) public asActor {
 36 | *r  |         morpho.createMarket(marketParams);
 37 |     | 
 38 |     |         t(_addMarket(marketParams), "duplicate market");
 39 |     |     }
```

`*r` on line 36 means hit + reverted

## debug with canary

Added canary to check if morpho_createMarket() ever succeeds:

```solidity
bool canaryCreateMarket;

function canary_morpho_createMarket() public {
    t(canaryCreateMarket, "morpho_createMarket not called");
}

function morpho_createMarket(MarketParams memory marketParams) public asActor {
    morpho.createMarket(marketParams);
    canaryCreateMarket = true;
}
```

result:
```bash
canary_morpho_createMarket(): failed!💥  
  Call sequence:
    CryticTester.canary_morpho_createMarket()
```

This seems to be a bad canary, echidna just calls canary first before any `morpho_createMarket()`:
1. calls canary_morpho_createMarket() first
2. canaryCreateMarket still false
3. t(false, ...) fails

Fixed canary, flip logic so it fails only when`morpho_createMarket()` succeeds (can ensure that we have at least one valid call):

```diff
function canary_morpho_createMarket() public {
-    t(canaryCreateMarket, "morpho_createMarket not called");
+    t(!canaryCreateMarket, "morpho_createMarket called");
}
```

## root cause (my guess)

Coverage shows `createMarket` hit but handler reverts because fuzzer passes random IRM address, then `createMarket` calls `irm.borrowRate()` and reverts (invalid IRM). echidna shows "hit" even for reverted calls

Why our current clamped version doesnt help? even with clamped tokens we dont enable IRM first. fuzzer needs to:
1. call `morpho_enableIrm(address(mockIRM))` with **exact address** (the valid irm)
2. then call `morpho_createMarket_clamped`(...)

so there is only 1 valid IRM address in entire address space, unlikely to find within test limit

(?) unlike LLTV (accepts uint256 < WAD), IRM needs exact address match

## solution

1. enable IRM in Setup (this only seems not enough).

2. Also enable LLTV `morpho_createMarket_clamped()` for not-yet enabled LLTVs (have to check for skipping already enabled LLTVs because if it try to enable already enabled LLTV, it will revert and in the `morpho_createMarket_clamped()` it will then block the scenario each market can have the same lltv)


result: 
```bash
canary_morpho_createMarket(): failed!💥  
  Call sequence:
    CryticTester.morpho_createMarket_clamped(0,0,0)
    CryticTester.canary_morpho_createMarket()

Traces: 
emit Log(«morpho_createMarket called») (/Users/filmptz/Desktop/Bootcamp/Recon-Invariant-Testing/assignments/week-2/morpho-blue/lib/chimera/src/CryticAsserts.sol:46)
```

**Finally got the valid case where `morpho_createMarket()` succeeds!**