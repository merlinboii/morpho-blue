# Morpho - Invariant Testing Playground

This repository is a fork of [Morpho Blue](https://github.com/morpho-org/morpho-blue) for practicing invariant testing. 
The original README can be found in [README_MORPHO.md](./README_MORPHO.md)

## Current work

- Setup repository
- Scaffolding Core Contract (Morpho) + Mocks components (ERC20, Oracle, IRM, ...)
    - 🔮 [Recon Extension](https://github.com/Recon-Fuzz/recon-extension)
- **Improving coverage**

## Repository Structure

What we will pay attention to:
- `merlinboii-lab/` - **My notes and experiments**
- `src/` - Core contracts
- **`test/recon/` - **My playground**
- `echidna.yaml` - Echidna configuration (default from recon extension scaffold)
- `foundry.toml` - Foundry configuration
    - disable `via_ir`
    - remove `bytecode_hash = "none"`

## Fuzzing Setup

Our fuzzing environment is intentionally constrained to focus testing on meaningful scenarios.

### Mocks

| Mock | Description |
|------|-------------|
| **MockERC20** | Standard ERC20 with `mint()` exposed for testing. Deployed with 3 decimal configurations: 0, 6, 18. |
| **MockIRM** | Interest rate model with arbitrary rate setting. Rate is **global** (not market-dependent) - applies to all markets using this IRM. |
| **OracleMock** | Price oracle with arbitrary price setting. Price is **global** (not token-dependent) - applies to all markets using this oracle. |

### Tokens

3 hardcoded ERC20 tokens with different decimals:
- `token_0` - 0 decimals
- `token_6` - 6 decimals  
- `token_18` - 18 decimals

This creates **9 possible market combinations** (3 loan × 3 collateral tokens).

### Actors

5 hardcoded actors pre-seeded with tokens and max approvals to Morpho:
- `address(this)` - test contract
- `address(0x12)`
- `address(0x34)`
- `address(0x56)`
- `address(0xff)`

### LLTVs

Guided set of governance-approved LLTVs (from [Morpho docs](https://docs.morpho.org/learn/concepts/market/#lltvs)):
- 0%, 38.5%, 62.5%, 77%, 86%, 91.5%, 94.5%, 96.5%, 98%

### Operable Markets

The fuzzer is limited to **operable markets** - markets where:
- `loanToken` ∈ configured tokens
- `collateralToken` ∈ configured tokens
- `irm` ∈ configured IRMs
- `oracle` ∈ configured oracles

Markets created with random/invalid params are tracked but not operated on.

### Limitations

| Constraint | Reason |
|------------|--------|
| Fixed 3 tokens | Focus on decimal edge cases without explosion of combinations |
| Fixed 5 actors | Reduce state space while covering multi-user scenarios |
| Guided LLTVs | Match real-world governance values |
| Global IRM rate | Simplify interest testing (rate changes affect all markets that use it) |
| Global oracle price | Simplify price testing (price changes affect all markets that use it) |
