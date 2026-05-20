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