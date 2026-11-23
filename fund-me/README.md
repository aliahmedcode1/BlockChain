# FundMe (Foundry)

A Foundry implementation of the Cyfrin Updraft **Foundry Fund Me** lesson: fund a contract with ETH (converted to USD via a Chainlink price feed) and let only the owner withdraw.

## What is inside

| Path | Purpose |
| --- | --- |
| `src/Fundme.sol` | Main contract. `fund()`, `withdraw()`, gas-optimized `cheaperWithdraw()`, getters. Storage variables use the `s_` prefix and are private. |
| `src/PriceConverter.sol` | Library that converts ETH to USD using `AggregatorV3Interface`. |
| `test/mock/MockV3Aggregator.sol` | Local price feed mock (8 decimals, version 4), deployed by `HelperConfig` on non-Sepolia chains. |
| `script/DeployFundMe.s.sol` | Deploys `FundMe` with the address from `HelperConfig`. |
| `script/HelperConfig.s.sol` | Returns the Sepolia feed address or deploys a mock locally. |
| `script/Interactions.s.sol` | `FundFundMe` / `WithdrawFundMe` scripts for a deployed contract. |
| `test/unit/FundMeTest.t.sol` | Unit tests (funding, funders list, owner restrictions, withdrawals, both withdraw variants). |
| `test/integration/InteractionsTest.t.sol` | Integration tests that exercise the interaction scripts end-to-end. |

## Setup

```bash
forge build
```

## Test

```bash
forge test -vv
forge test --match-test testWithdrawFromMultipleFunders -vvvv
forge coverage
forge snapshot
```

Tests work both locally (mock feed) and on a Sepolia fork:

```bash
forge test --fork-url $SEPOLIA_RPC_URL
```

## Deploy

Local Anvil:

```bash
anvil
forge script script/DeployFundMe.s.sol:DeployFundME --rpc-url http://127.0.0.1:8545 --broadcast
```

Sepolia:

```bash
source .env
forge script script/DeployFundMe.s.sol:DeployFundME \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv
```

## Fund / withdraw a deployed contract

```bash
export FUNDME_ADDRESS=<deployed address>

forge script script/Interactions.s.sol:FundFundMe \
  --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast

forge script script/Interactions.s.sol:WithdrawFundMe \
  --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

`WithdrawFundMe` only works when called by the contract owner.
