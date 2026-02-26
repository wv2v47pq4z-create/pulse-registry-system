# Copilot Instructions for pulse-registry-system

This repository contains Solidity smart contracts for the PulseRegistry and ZcashBridge systems — an auto-registration and interoperability layer for Super Reality Studios' blockchain ecosystem.

## Project Overview

- **PulseRegistry**: On-chain registry for automated entity registration.
- **ZcashBridge**: Interoperability bridge connecting the registry to Zcash-compatible chains.
- **Tooling**: Remix IDE / Remix compiler (`remixd`), Solidity.

## Repository Structure

- `contracts/` – Solidity smart contract source files (`.sol`)
- `scripts/` – Deployment and utility scripts
- `tests/` – Contract test files
- `artifacts/` – Compiled contract outputs (gitignored)

## Code Standards

### Solidity
- Target Solidity `^0.8.x` unless a contract explicitly requires a different version.
- Always specify a `pragma solidity` version at the top of every file.
- Use `SPDX-License-Identifier` headers on all contract files.
- Prefer `custom errors` over `require` strings for gas efficiency (Solidity ≥ 0.8.4).
- Follow the [Solidity style guide](https://docs.soliditylang.org/en/latest/style-guide.html): `UpperCamelCase` for contracts/events, `mixedCase` for functions/variables, `UPPER_CASE` for constants.
- Avoid `tx.origin` for authorization; use `msg.sender`.
- Mark functions with the most restrictive visibility (`external` preferred over `public` where applicable).
- Add NatSpec (`@notice`, `@param`, `@return`) comments to all public/external functions.

### Security
- Never commit secrets, private keys, or mnemonic phrases.
- Keep `.env` and `.env.local` out of version control (already in `.gitignore`).
- Validate all external inputs; use `require` or custom errors with descriptive messages.
- Protect against reentrancy using the checks-effects-interactions pattern or `ReentrancyGuard`.

## Development Workflow

### Build
Compile contracts using Hardhat or Foundry (recommended, as they handle import paths and dependencies automatically):
```bash
# Hardhat
npx hardhat compile

# Foundry
forge build
```

### Test
Run contract tests (Hardhat or Foundry if configured):
```bash
# Hardhat
npx hardhat test

# Foundry
forge test
```

### Lint
```bash
npx solhint 'contracts/**/*.sol'
```

## Key Guidelines

1. Write unit tests for every new contract function.
2. Document all public and external functions with NatSpec.
3. Keep contracts modular — avoid monolithic contracts.
4. Update `README.md` when adding new contracts or changing interfaces.
5. Do not update lock files unless dependencies actually change.
