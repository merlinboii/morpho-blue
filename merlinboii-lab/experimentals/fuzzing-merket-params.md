## Fuzzing Market Params

## Tool
- Echidna

## Problem
- Coverage Report: [covered.1779277907.html](echidna/covered.1779277907.html), the target function got hit but the coverage shows that it only went deep until the market check: 
Examples:
```text
 200 | *   |     function withdraw(
 201 |     |         MarketParams memory marketParams,
 202 |     |         uint256 assets,
 203 |     |         uint256 shares,
 204 |     |         address onBehalf,
 205 |     |         address receiver
 206 | *   |     ) external returns (uint256, uint256) {
 207 | *   |         Id id = marketParams.id();
 208 | *   |         require(market[id].lastUpdate != 0, ErrorsLib.MARKET_NOT_CREATED);
 209 |     |         require(UtilsLib.exactlyOneZero(assets, shares), ErrorsLib.INCONSISTENT_INPUT);
```
```text
 346 |     |     /// @inheritdoc IMorphoBase
 347 | *   |     function liquidate(
 348 |     |         MarketParams memory marketParams,
 349 |     |         address borrower,
 350 |     |         uint256 seizedAssets,
 351 |     |         uint256 repaidShares,
 352 |     |         bytes calldata data
 353 | *   |     ) external returns (uint256, uint256) {
 354 | *   |         Id id = marketParams.id();
 355 | *   |         require(market[id].lastUpdate != 0, ErrorsLib.MARKET_NOT_CREATED);
 356 |     |         require(UtilsLib.exactlyOneZero(seizedAssets, repaidShares), ErrorsLib.INCONSISTENT_INPUT);
```

- This would mean the fuzzer is not able to generate valid market params that can pass the market check even though we have created the market.

```text
 149 |     |     /// @inheritdoc IMorphoBase
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

- It can also be seen in the example logs: [corpus.9144184742028675049.json](merlinboii-lab/experimentals/corpus.9144184742028675049.json)

One of `morpho_createMarket(MarketParams memory marketParams)` call in the log:
```json
{
    //--- snipped ---
    {
        "call": {
        "contents": [
            "morpho_createMarket",
            [
            {   // marketParams
                "contents": [
                {   // loanToken
                    "contents": "0xF62849F9A0B5Bf2913b396098F7c7019b51A820a",
                    "tag": "AbiAddress"
                },
                {   // collateralToken
                    "contents": "0x00000000000000000000000000000002fFffFffD",
                    "tag": "AbiAddress"
                },
                {   // oracle
                    "contents": "0x00000000000000000000000000000001fffffffE",
                    "tag": "AbiAddress"
                },
                {   // irm
                    "contents": "0xc7183455a4C133Ae270771860664b6B7ec320bB1",
                    "tag": "AbiAddress"
                },
                {   // lltv
                    "contents": [
                    256,
                    "50408852012349240217673327766259700739012908288565205684768952413494502678237"
                    ],
                    "tag": "AbiUInt"
                }
                ],
                "tag": "AbiTuple"
            }
            ]
        ],
        "tag": "SolCall"
        },
        ...
    }
    //--- snipped ---
}
```

One of `morpho_supply(MarketParams memory marketParams, uint256 assets, uint256 shares, address onBehalf, bytes memory data)` call in the log:
```json
{
    //--- snipped ---
    {
        "call": {
        "contents": [
            "morpho_supply",
            [
            {   // marketParams
                "contents": [
                {   // loanToken
                    "contents": "0xc7183455a4C133Ae270771860664b6B7ec320bB1",
                    "tag": "AbiAddress"
                },
                {   // collateralToken
                    "contents": "0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38",
                    "tag": "AbiAddress"
                },
                {   // oracle
                    "contents": "0x00000000000000000000000000000000FFFFfFFF",
                    "tag": "AbiAddress"
                },
                {   // irm
                    "contents": "0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38",
                    "tag": "AbiAddress"
                },
                {   // lltv
                    "contents": [256, "162"], 
                    "tag": "AbiUInt" 
                }
                ],
                "tag": "AbiTuple"
            },
            {   // assets
                "contents": [
                256,
                "115792089237316195423570985008687907853269984665640564039457584007913096099418"
                ],
                "tag": "AbiUInt"
            },
            {   // shares
                "contents": [
                256,
                "17745293103860075860043662246918174437918624516465025806674449190444376534671"
                ],
                "tag": "AbiUInt"
            },
            {   // onBehalf
                "contents": "0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9",
                "tag": "AbiAddress"
            },
            {   // data
                "contents": "\"e.95\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\SOH\\255\\255\\255\\254\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\NUL\\152\\131\\201\\146\\199\\199\\179\\212\\223\\SOHA\\223\\156\\195\\STX\\176\"",
                "tag": "AbiBytesDynamic"
            }
            ]
        ],
        "tag": "SolCall"
        },
        ...
  }
  //--- snipped ---
}
```

- As in Morpho the distinction between markets (market id) is the combination of the market params, we can see that the fuzzer seems to view the market params as a tuple of 5 elements (as per `MarketParams` struct), not as a single struct entity.

- So it looks like it does not remember the combination of the 5 params as a single entity (or it might take too long, so it finally fuzzes another time with the combination of 5 fuzzed values that finally correspond to the existing market 🚸 need confirmation).

## Solution (idea)
Help the fuzzer remember the created market params: 
- Use a global variable to help map the valid market and expose it to the fuzzer

## Try-on solutions

### How to store market
1. Using the `Id` (based on morpho lib Id calculator) as key
    - `mapping(Id => MarketParams);`
    - Is this biased to help the fuzzer prevent trying to create the same market again, as we can automatically skip if it produced the same id? 
    
    - Even in Morpho code it has a check `market[id].lastUpdate == 0` before creating a market. Would it be better to let the fuzzer know the created market and let Morpho prevent it by itself? Also, if something weird happens and we have a duplicate market id in our test storage, that means Morpho might have a bug that lets us create a duplicate market.

    - Is it also hard to make a switch market handler exposed to the fuzzer?

2. Using the array index and storing it as a struct array
    - `MarketParams[];`
    - Only the value of each `MarketParams` is hard to ensure no duplicates (we need to do field by field and all fields need to match) or hash all fields and compare, but that brings us back to the `Id` idea
    - `Id` might still be a good idea; using it from the Morpho lib means we implicitly test the Morpho lib here as well—if it produces a duplicate, something weird happened

3. Using both (Enumerable + Mapping)
    - `Bytes32Set (for Id as it is bytes32)` -> need to check when adding; if it returns `false`, we found a duplicate
    - `mapping(Id => MarketParams)`

### How to expose to fuzzer
1. Create handler to switch the **current** market so any target execution will then use the current market in its execution
2. Fuzz the index instead of passing `MarketParams memory marketParams` for each market-related function

The `1.` would be better, the result is the same (choose the market to work on) so ler fuzzer explicitly choose it with the switch market handler
