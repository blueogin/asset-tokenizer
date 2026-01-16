# Asset Tokenizer - Upgradeable ERC20 Token

A secure, UUPS-upgradeable smart contract representing a tokenized financial asset, built with Foundry and OpenZeppelin.

## Overview

This project implements a tokenized financial asset using the UUPS (Universal Upgradeable Proxy Standard) pattern. The contract supports:
- ERC20 token functionality
- Role-based access control (Admin and Minter roles)
- Supply cap with custom error handling
- Upgradeability to future versions (demonstrated with V2 adding pause functionality)

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Solidity compiler version ^0.8.20
- OpenZeppelin Contracts Upgradeable (installed via `forge install`)

## Setup

1. **Clone the repository** (if applicable) or navigate to the project directory

2. **Install dependencies**:
   ```bash
   forge install OpenZeppelin/openzeppelin-contracts-upgradeable
   ```

3. **Build the project**:
   ```bash
   forge build
   ```

4. **Run tests**:
   ```bash
   forge test
   ```

## Deployment

### Local Development (Anvil)

1. **Start a local Anvil node**:
   ```bash
   anvil
   ```

2. **Set environment variables**:
   ```bash
   export PRIVATE_KEY=<your_private_key>
   export ADMIN_ADDRESS=<admin_address>
   export MAX_SUPPLY=1000000000000000000000000  # 1M tokens (optional, defaults to 1M)
   ```

3. **Deploy the contract**:
   ```bash
   forge script script/DeployAssetToken.s.sol:DeployAssetToken --rpc-url http://localhost:8545 --broadcast
   ```

### Testnet/Mainnet Deployment

1. **Set environment variables**:
   ```bash
   export PRIVATE_KEY=<your_private_key>
   export ADMIN_ADDRESS=<admin_address>
   export MAX_SUPPLY=1000000000000000000000000  # Optional
   ```

2. **Deploy**:
   ```bash
   forge script script/DeployAssetToken.s.sol:DeployAssetToken \
     --rpc-url <your_rpc_url> \
     --broadcast \
     --verify \
     --etherscan-api-key <your_api_key>
   ```

## Testing

The test suite covers:

1. **V1 Deployment**: Verifies proper initialization with name, symbol, max supply, and roles
2. **Minting**: Tests minting functionality, events, and max supply enforcement
3. **Transfers**: Standard ERC20 transfer functionality
4. **Upgrade Lifecycle**: Complete upgrade from V1 to V2
5. **State Persistence**: Verifies balances persist after upgrade
6. **V2 Functionality**: Tests pause/unpause functionality
7. **Access Control**: Ensures only authorized roles can perform actions

Run all tests:
```bash
forge test
```

Run with verbose output:
```bash
forge test -vvv
```

Run specific test:
```bash
forge test --match-test test_UpgradeLifecycle
```

## Storage Layout Safety

### Storage Layout Verification

The storage layout is safe for upgrades because:

1. **V1 Storage Layout**:
   - Inherits from `ERC20Upgradeable` (storage slots 0-7)
   - Inherits from `AccessControlUpgradeable` (adds role storage)
   - Adds `maxSupply` at a new storage slot

2. **V2 Storage Layout**:
   - Inherits all storage from V1 (`AssetToken`)
   - Inherits from `PausableUpgradeable` which adds:
     - `_paused` boolean at a new storage slot
   - No reordering or removal of existing storage variables

3. **Verification Method**:
   - Used OpenZeppelin's storage layout inheritance pattern
   - V2 only adds new storage variables (append-only)
   - No existing storage variables were modified or removed
   - Used `reinitializer(2)` to properly initialize V2 without affecting existing storage

### Storage Slot Analysis

- **Slot 0-7**: ERC20 state (balances, allowances, totalSupply, etc.)
- **Slot 8+**: AccessControl roles mapping
- **Slot N**: `maxSupply` (uint256)
- **Slot N+1**: `_paused` (bool, added in V2)

The storage layout follows the append-only pattern recommended by OpenZeppelin, ensuring that:
- Existing data remains intact after upgrade
- New functionality doesn't corrupt existing state
- Storage slots are never reused or reordered

## License

MIT
