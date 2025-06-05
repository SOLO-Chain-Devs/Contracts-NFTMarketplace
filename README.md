# NFT Marketplace Smart Contract

A robust and secure NFT marketplace implementation supporting ERC721, ERC1155, and ERC6909 tokens with multi-currency support and optional curation controls.

## Features

- **Multi-Token Support**: Compatible with ERC721, ERC1155, and ERC6909 NFTs
- **Multi-Currency**: Support for ETH and any ERC20 token as payment method
- **Bidding System**: Advanced bidding functionality with customizable duration
- **Optional Curation**: Configurable gatekeeping system for curated marketplace experiences
- **Marketplace Operations**:
  - List NFTs for sale
  - Place bids with custom timeouts
  - Accept bids
  - Cancel listings
  - Cancel bids (with configurable cancellation fees)
- **Admin Controls**:
  - Currency whitelist management
  - Bid duration settings
  - Cancellation fee configuration
  - Curation system toggle and validator management

## Smart Contract Architecture

The marketplace is built with a modular architecture consisting of:

- **Core**: Main marketplace functionality with unified multi-token support
- **Storage**: State variables and data structures
- **Admin**: Privileged operations and configurations including curation controls
- **Views**: Read-only functions for querying market state
- **Libraries**: Reusable utilities for token handling and payments
- **Curation**: Optional validation layer for marketplace access control

## Development Environment

This project uses Foundry, a fast and flexible Ethereum development environment.

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Solidity ^0.8.27

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd <repository-name>
```

2. Install dependencies:
```bash
forge install
```

3. Build the project:
```bash
forge build --via-ir
```

### Testing

Run the test suite:
```bash
forge test --via-ir
```

Run tests with gas reporting:
```bash
forge test --via-ir --gas-report
```

### Code Formatting

Format your Solidity code:
```bash
forge fmt
```

## Deployment

1. Set up your environment variables in a .env based on .env.example:
```bash
cp .env.example .env
```

2. (Optional) Fork network with Anvil

```bash
source .env &&
anvil --fork-url $ONCHAIN_RPC_URL --fork-block-number 10530428 --accounts 10 --balance 1000 --chain-id $OFFCHAIN_CHAIN_ID --block-time 3
```

3. Deploy contracts to your chosen network:

```bash
forge script script/MarketplaceDeploy.s.sol:MarketplaceDeployScript \
  --rpc-url $OFFCHAIN_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
  --legacy
```

```bash
forge script script/FactoryDeploy.s.sol:FactoryDeployScript \
  --rpc-url $OFFCHAIN_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
  --legacy
```

And if you'd like to deploy and verify the smart contracts it should look like:

```bash
source .env &&
forge script script/FactoryDeploy.s.sol:FactoryDeployScript \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \ 
  --legacy \
  --verify \
  --verifier blockscout \
  --verifier-url $EXPLORER 
```

Note: **--legacy IS IMPORTANT on certain chains** Otherwise deployment fails.

4. Off chain Playground (Create NFTs, Bid, buy, sell ...)

Create some 721
```bash
source .env &&
forge script script/offChainPlayground/NFTFactory.s.sol:Create721 \
  --rpc-url $OFFCHAIN_RPC_URL \
  --broadcast
```

Create some 1155
```bash
source .env &&
forge script script/offChainPlayground/NFTFactory.s.sol:Create1155 \
  --rpc-url $OFFCHAIN_RPC_URL \
  --broadcast
```

Create some 6909
```bash
source .env &&
forge script script/offChainPlayground/NFTFactory.s.sol:Create6909 \
  --rpc-url $OFFCHAIN_RPC_URL \
  --broadcast
```

...

## Security Features

- Reentrancy protection
- Access control for admin functions
- Optional curation system for marketplace access control
- Fee handling in basis points for precision
- Support for safe token transfers
- Custom durations for bids
- Configurable cancellation fees

## Contract Interactions

### For NFT Owners
```solidity
// List an NFT
createListing(tokenAddress, tokenId, amount, price, currency)

// Accept a bid
acceptBid(tokenAddress, tokenId, tokenAmount)

// Cancel a listing
cancelListing(listingId)
```

### For Buyers
```solidity
// Place a bid
placeBid(tokenAddress, tokenId, tokenAmount, currency, amount, customDuration)

// Buy a listed NFT
buyListing(listingId)

// Cancel a bid
cancelBid(tokenAddress, tokenId, tokenAmount)
```

### For Admin
```solidity
// Set accepted currencies
setAcceptedCurrencies(currencies[], accepted[])

// Set bid duration
setBidDuration(newDuration)

// Set cancellation fee
setCancellationFeePercentage(newPercentage)

// Configure curation system
setCurationEnabled(enabled)
setCurationValidator(validatorAddress)
```

## Curation System

The marketplace includes an optional curation system that allows administrators to control which NFT collections can be listed and bid upon. This feature enables both permissionless and curated marketplace experiences.

### Curation Features
- **Toggle Control**: Enable or disable curation system at any time
- **Validator Contracts**: Pluggable validation logic through external contracts
- **Dynamic Approval**: Real-time approval/disapproval of collections
- **Granular Control**: Per-collection approval management

### Implementation
When enabled, the curation system validates all listing and bidding operations against an external validator contract. This allows for flexible curation policies while maintaining marketplace core functionality.

