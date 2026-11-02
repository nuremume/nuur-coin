# Nuur Coin (NC)

Stage 1 ERC-20 contract for the Nuur digital financial ecosystem.

This repository contains the Stage 1 token contract and a separate, simulated NUUR Wallet browser prototype in `wallet-prototype/`. It does not contain a production wallet backend, custody integration, or financial transaction service.

**Do not deploy to a production blockchain.** Use Anvil (local) or a public testnet.

## Architecture (locked for Stage 1)

| Item | Choice |
| --- | --- |
| Standard | ERC-20 (OpenZeppelin v5) |
| Name / symbol | `Nuur Coin` / `NC` (fixed in bytecode) |
| Decimals | 18 |
| Supply | 1,000,000,000 NC minted once in the constructor |
| Cap | Immutable; equals the genesis mint |
| Admin | None after deployment (no Ownable, no roles) |
| Extra features | `permit` (EIP-2612), holder-initiated `burn` |
| Explicitly excluded | Hidden mint, transfer tax, pause, blacklist, proxies |

The genesis recipient is an **operational** privilege (they hold the coins), not a contract backdoor. Treat that address as a treasury.

## Contract functions

### Constructor `constructor(address initialRecipient, uint256 initialSupply)`

Sets the ERC-20 name/symbol, records `initialSupply` as the immutable cap, and mints that amount to `initialRecipient`. Reverts if the recipient is `address(0)` or the supply is `0`.

### `name` / `symbol` / `decimals` / `totalSupply` / `cap` / `balanceOf`

Standard metadata and accounting. `cap()` never changes. `totalSupply()` falls if tokens are burned.

### `transfer` / `transferFrom`

Move tokens. The amount received equals the amount sent. There is no fee, reflection, max-tx, or cooldown.

### `approve` / `allowance`

Standard allowances for third parties (DEX routers, a future wallet relayer, etc.).

### `permit` / `nonces` / `DOMAIN_SEPARATOR`

EIP-2612 gasless approval. A signature can set an allowance without an `approve` transaction. Signatures can be phished; treat `permit` as an approval, not as a payment intent.

### `burn` / `burnFrom`

Destroy tokens from the caller, or from an account that has approved the caller. This is the only way supply decreases. There is no unburn.

### What is not present

There is no `mint`, `pause`, `owner`, `setTax`, or upgrade function. Tests assert that `mint(address,uint256)` and `owner()` are not callable.

## Security considerations

| Risk | Notes |
| --- | --- |
| Treasury key | Entire supply sits with `initialRecipient` until distributed. Use a hardware wallet or multisig for any public testnet run. |
| Infinite approve / permit phishing | Unchanged ERC-20/EIP-2612 issue. Document for wallet UX later. |
| No pause | Stolen funds cannot be frozen. This is intentional so the contract cannot freeze holders. |
| Non-upgradeable | Bugfixes require a new token and a migration. Prevents silent logic swaps. |
| Production deploy | `script/DeployNuurCoin.s.sol` reverts on known mainnet chain IDs. |

## Tooling

- Solidity `0.8.24`
- Foundry
- OpenZeppelin Contracts (git submodule under `lib/openzeppelin-contracts`)

### Build and test

```bash
export PATH="$PATH:$HOME/.foundry/bin"
forge build
forge test -vv
```

### Local deploy (Anvil)

```bash
anvil
cp .env.example .env
# Anvil account #0 is the default recipient in .env.example
source .env
forge script script/DeployNuurCoin.s.sol --rpc-url anvil --broadcast --private-key <anvil-private-key>
```

### Public testnet

Point `SEPOLIA_RPC_URL` (or Base Sepolia) at a test RPC, set `INITIAL_RECIPIENT` to a test wallet you control, then:

```bash
forge script script/DeployNuurCoin.s.sol --rpc-url sepolia --broadcast
```

Do not use Ethereum, Base, Arbitrum, Polygon, BSC, Optimism, or Avalanche mainnet with this script.

## Layout

```
src/NuurCoin.sol                 Token
script/DeployNuurCoin.s.sol      Local / testnet deploy
test/NuurCoin.t.sol              Unit + fuzz tests
test/NuurCoin.invariant.t.sol    Supply invariants
test/DeployNuurCoin.t.sol        Deploy-script guards
wallet-prototype/                Simulated browser UI; no wallet connection
NUUR_WALLET_ARCHITECTURE.md      Proposed custodial platform baseline
NUUR_WALLET_THREAT_MODEL.md      Initial threat model and security test plan
NUUR_WALLET_ADRS.md              Proposed and accepted architecture decisions
SECURITY_ENGINEERING_REQUIREMENTS.md  Mandatory per-feature security gate
```

## License

MIT (token). OpenZeppelin remains under its upstream MIT license.
