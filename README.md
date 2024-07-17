# Zaros

- [Zaros](#zaros)
    - [Prize Pool](#prize-pool)
    - [Stats](#stats)
- [Contest Details](#contest-details)
  - [About](#about)
- [Tree Proxy Pattern](#tree-proxy-pattern)
  - [Zaros Protocol's novel Architecture - Tree Proxy Pattern](#zaros-protocols-novel-architecture---tree-proxy-pattern)
  - [Relevant links](#relevant-links)
  - [Actors](#actors)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Quickstart](#quickstart)
- [Usage](#usage)
  - [Coverage](#coverage)
- [Scope](#scope)
  - [Compatibilities](#compatibilities)
  - [Known Issues](#known-issues)

### Prize Pool

- Total Pool - $60,000
- H/M - $50,000
- Low - $5,500
- Community Judging - $4,500

- Starts: July 17, 2024 Noon UTC
- Ends: July 31, 2024 Noon UTC

### Stats

nSloc - 2878


[//]: # (contest-details-open)

# Contest Details

## About

Zaros is a Perpetuals DEX powered by Boosted (Re)Staking Vaults. It seeks to maximize LPs yield generation, while offering a
top-notch trading experience on Arbitrum (and Monad in the future).

Zaros connects Liquid Re(Staking) Tokens (LSTs & LRTs) and other yield bearing collateral types with its Perpetual Futures
Engine, allowing LPs to amplify their returns with additional APY coming from trading fees. The protocol is composed of two
separate, interconnected smart contracts systems:

- The Perpetuals Trading Engine (`PerpsEngine` root proxy contract).
- THe Market Making Engine (`MarketMakingEngine` root proxy contract).

The Market Making Engine is responsible by the creation of the ZLP Vaults and the delegation of their underlying liquidity to
markets managed by the Perpetuals Trading Engine. In this first phase, the codebase presents the smart contracts that define
the functionality of the `PerpsEngine`.

# Tree Proxy Pattern

## Zaros Protocol's novel Architecture - Tree Proxy Pattern

Tree Proxy Pattern is our novel modular, and opinionated proxy pattern solution designed to address key industry problems
faced by large smart contract systems, by introducing the following solutions:

- Simplified terminology (Compared to e.g EIP-2535)
- EIP-7201 compatible
- Clear testing paths (leveraging [BTT](https://github.com/PaulRBerg/btt-examples))
- Composability over inheritance
- Upgradeability

  > **_NOTE:_** The pattern is still in a preliminary version.

## Relevant links

- [TPP Documentation](https://docs.zaros.fi/overview/getting-started/tree-proxy-pattern)
- [Zaros Gitbook](https://docs.zaros.fi/overview)
- [Github](https://github.com/zaros-labs/zaros-core)
- [X](https://x.com/zarosfi)
- [Website](https://www.zaros.fi/)
- [Live Alpha Testnet](https://testnet.app.zaros.fi/)

## Actors

- eDAO (Trusted): The "Executioner DAO" role. It's a multi-sig wallet responsible by configuring protocol parameters and is set as the
  `owner`.
- Trader: Protocol user which may call all non-restricted external functions.
- Market Order Keeper (Trusted): Chainlink Automation compatible contract that is reponsible by filling market orders.
- Liquidation Keeper (Trusted): Chainlink Automation compatible contract or allowlisted EOA that has the permission of liquidating
  trading accounts when their MMR is below 1.
- Offchain Orders Keeper (Trusted): EOA responsible by filling offchain offchain orders (e.g Limit, TP/SL).

[//]: # (contest-details-close)

[//]: # (getting-started-open)

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like
  `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

## Installation

```bash
git clone https://github.com/Cyfrin/2024-07-zaros.git
cd 2024-07-zaros
make
````

## Quickstart

```bash
make test
```

# Usage

## Coverage

```bash
forge test --report debug
```

[//]: # (getting-started-close)

[//]: # (scope-open)

# Scope

**NOTE**
_**The repo code is the final word on functionality. Protocol documentation may not be the most up to date.**_

- Files in scope:

```
make scope
```

```bash
#-- account-nft
|   #-- AccountNFT.sol
|   #-- interfaces
|       #-- IAccountNFT.sol
#-- external
|   #-- chainlink
|       #-- ChainlinkUtil.sol
|       #-- interfaces
|       |   #-- IAggregatorV3.sol
|       |   #-- IAutomationCompatible.sol
|       |   #-- IFeeManager.sol
|       |   #-- ILogAutomation.sol
|       |   #-- IOffchainAggregator.sol
|       |   #-- IStreamsLookupCompatible.sol
|       |   #-- IVerifierProxy.sol
|       #-- keepers
|           #-- BaseKeeper.sol
|           #-- liquidation
|           |   #-- LiquidationKeeper.sol
|           #-- market-order
|               #-- MarketOrderKeeper.sol
#-- perpetuals
|   #-- PerpsEngine.sol
|   #-- branches
|   |   #-- GlobalConfigurationBranch.sol
|   |   #-- LiquidationBranch.sol
|   |   #-- OrderBranch.sol
|   |   #-- PerpMarketBranch.sol
|   |   #-- SettlementBranch.sol
|   |   #-- TradingAccountBranch.sol
|   #-- leaves
|       #-- CustomReferralConfiguration.sol
|       #-- FeeRecipients.sol
|       #-- GlobalConfiguration.sol
|       #-- MarginCollateralConfiguration.sol
|       #-- MarketConfiguration.sol
|       #-- MarketOrder.sol
|       #-- OffchainOrder.sol
|       #-- OrderFees.sol
|       #-- PerpMarket.sol
|       #-- Position.sol
|       #-- Referral.sol
|       #-- SettlementConfiguration.sol
|       #-- TradingAccount.sol
#-- tree-proxy
|   #-- RootProxy.sol
|   #-- branches
|   |   #-- LookupBranch.sol
|   |   #-- UpgradeBranch.sol
|   #-- leaves
|       #-- Branch.sol
|       #-- LookupTable.sol
|       #-- RootUpgrade.sol
#-- usd
|   #-- USDToken.sol
#-- utils
    #-- Constants.sol
    #-- Errors.sol
    #-- Math.sol
```

## Compatibilities

- Solc Version: 0.8.25
- Chain(s) to deploy to:
  - Arbitrum

Tokens:
    - WETH
    - WEETH
    - WSTETH
    - WBTC
    - USDC
    - USDT
    - USDE
    - SUSDE
    - ERC721 (Zaros Account NFT, AccountNFT.sol)

[//]: # (scope-close)

[//]: # (known-issues-open)

## Known Issues

- Centralization vectors: we're aware that the multi-sig responsible by configuring protocol parameters has admin
  permissions. This will be improved as the Zaros DAO decentralizes and implements onchain voting.
- Gas volatility risk: In rare scenarios of extreme gas spikes on the Arbitrum network, filling market orders and liquidating
  accounts could temporarily turn unprofitable for keepers. This may be mitigated by emergency pausing the markets if happens
  for a prolonged period, or through additional financing from the DAO.
- Function selectors of all branches must be explicitly set in order to be callable at the `RootProxy`.

Any issues as detailed by the previous Cyfrin audit report available [Here](https://github.com/Cyfrin/cyfrin-audit-reports/blob/main/reports/2024-07-13-cyfrin-zaros-v2.0.pdf)

[//]: # (known-issues-close)
