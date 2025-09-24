# PropTokens Smart Contract

## Overview

**PropTokens** is a smart contract built on the Stacks blockchain using Clarity that enables fractional synthetic ownership of premium real estate properties worldwide. The contract allows users to purchase, trade, and manage tokenized fractions of high-value real estate assets without the traditional barriers of property investment.

## Features

### 🏠 Property Tokenization
- Convert real estate properties into divisible digital tokens
- Set custom token supply and pricing for each property
- Track property metadata (name, location, total value)

### 💰 Fractional Ownership
- Purchase fractional ownership with STX tokens
- Calculate exact ownership percentages
- Transfer ownership between users seamlessly

### 📊 Portfolio Management
- View all owned properties and token balances
- Track ownership percentages across multiple properties
- Monitor property values and price changes

### 🔒 Secure Operations
- Authorization-based property management
- Input validation and error handling
- Protected admin functions

## Contract Architecture

### Data Structures

- **Properties**: Core property information and tokenization details
- **Property Balances**: Individual token holdings per user per property
- **Property Owners**: Lists of token holders for each property

### Key Constants

```clarity
CONTRACT_OWNER          - Contract deployer with admin privileges
ERR_UNAUTHORIZED        - Access denied error
ERR_PROPERTY_NOT_FOUND  - Invalid property ID error
ERR_INSUFFICIENT_BALANCE - Insufficient token balance error
ERR_INVALID_AMOUNT      - Invalid amount specified error
```

## Functions

### Read-Only Functions

#### `get-property-info(property-id)`
Returns detailed information about a specific property.
- **Parameters**: `property-id` (uint)
- **Returns**: Property details or none

#### `get-balance(property-id, owner)`
Returns the token balance for a specific owner and property.
- **Parameters**: `property-id` (uint), `owner` (principal)
- **Returns**: Token balance (uint)

#### `get-total-properties()`
Returns the total number of properties created.
- **Returns**: Total property count (uint)

#### `calculate-ownership-percentage(property-id, owner)`
Calculates the ownership percentage for a specific owner.
- **Parameters**: `property-id` (uint), `owner` (principal)
- **Returns**: Percentage * 100 (e.g., 1500 = 15.00%)

### Public Functions

#### `create-property(name, location, total-value, total-supply)`
Creates a new tokenizable property (admin only).
- **Parameters**: 
  - `name` (string-ascii 100): Property name
  - `location` (string-ascii 100): Property location
  - `total-value` (uint): Total property value in STX
  - `total-supply` (uint): Number of tokens to create
- **Returns**: Property ID (uint)

#### `buy-tokens(property-id, amount)`
Purchase tokens for fractional ownership.
- **Parameters**: 
  - `property-id` (uint): Target property ID
  - `amount` (uint): Number of tokens to purchase
- **Returns**: Tokens purchased (uint)

#### `transfer-tokens(property-id, amount, sender, recipient)`
Transfer tokens between users.
- **Parameters**: 
  - `property-id` (uint): Property ID
  - `amount` (uint): Tokens to transfer
  - `sender` (principal): Token sender
  - `recipient` (principal): Token recipient
- **Returns**: Success status (bool)

#### `sell-tokens(property-id, amount)`
Sell tokens back to the contract.
- **Parameters**: 
  - `property-id` (uint): Property ID
  - `amount` (uint): Tokens to sell
- **Returns**: Tokens sold (uint)

#### `update-property-value(property-id, new-value)`
Update property valuation (admin only).
- **Parameters**: 
  - `property-id` (uint): Property ID
  - `new-value` (uint): New property value
- **Returns**: Success status (bool)

## Deployment Guide

### Prerequisites
- Stacks blockchain testnet/mainnet access
- Clarinet CLI for local development
- STX tokens for deployment and testing

### Local Development

1. **Install Clarinet**
   ```bash
   curl -L https://github.com/hirosystems/clarinet/releases/latest/download/clarinet-linux-x64.tar.gz | tar xz
   ```

2. **Create Project**
   ```bash
   clarinet new prop-tokens-project
   cd prop-tokens-project
   ```

3. **Add Contract**
   - Copy the PropTokens contract code to `contracts/prop-tokens.clar`
   - Update `Clarinet.toml` to include the contract

4. **Test Contract**
   ```bash
   clarinet test
   clarinet console
   ```

### Testnet Deployment

1. **Configure Network**
   ```bash
   clarinet deploy --network testnet
   ```

2. **Deploy Contract**
   ```bash
   clarinet publish --network testnet
   ```

## Usage Examples

### Creating a Property

```clarity
;; Create a luxury apartment in Manhattan
(contract-call? .prop-tokens create-property
  "Manhattan Penthouse"
  "New York, NY, USA"
  u50000000  ;; $500,000 in STX (assuming 1 STX = $1)
  u1000      ;; 1,000 tokens
)
```

### Buying Tokens

```clarity
;; Buy 50 tokens of property #1
(contract-call? .prop-tokens buy-tokens u1 u50)
```

### Transferring Tokens

```clarity
;; Transfer 25 tokens to another user
(contract-call? .prop-tokens transfer-tokens 
  u1 
  u25 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 
  'SP3K8BC0PPEVCV7NZ6QSRWPQ2JE9E5B6N3PA0KBR9
)
```

### Checking Ownership

```clarity
;; Check ownership percentage
(contract-call? .prop-tokens calculate-ownership-percentage 
  u1 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7
)
```

## Security Considerations

### Access Control
- Only contract owner can create properties and update valuations
- Users can only transfer their own tokens
- All functions include proper authorization checks

### Input Validation
- All numeric inputs are validated for positive values
- Balance checks prevent overselling
- Property existence verification

### Economic Security
- Token prices are automatically calculated based on property value
- STX transfers are atomic with token minting/burning
- No external oracle dependencies reduce attack vectors

## Integration Guide

### Frontend Integration

```javascript
// Example using Stacks.js
import { callReadOnlyFunction, callPublicFunction } from '@stacks/transactions';

// Get property info
const propertyInfo = await callReadOnlyFunction({
  contractAddress: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
  contractName: 'prop-tokens',
  functionName: 'get-property-info',
  functionArgs: [uintCV(1)],
  network: new StacksTestnet()
});

// Buy tokens
const buyTokens = await callPublicFunction({
  contractAddress: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
  contractName: 'prop-tokens',
  functionName: 'buy-tokens',
  functionArgs: [uintCV(1), uintCV(100)],
  senderKey: privateKey,
  network: new StacksTestnet()
});
```

## Roadmap

### Phase 1 - Core Features ✅
- Basic property tokenization
- Token buying/selling
- Transfer functionality
- Ownership tracking

### Phase 2 - Enhanced Features (Planned)
- Dividend distributions
- Voting mechanisms for property decisions
- Multi-signature property management
- Property performance analytics

### Phase 3 - Advanced Features (Future)
- Cross-chain compatibility
- DeFi integrations (lending/borrowing against tokens)
- Property management DAOs
- Real estate market oracle integration

## Contributing

We welcome contributions to improve PropTokens! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request with detailed description

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For technical support and questions:
- Create an issue in the GitHub repository

## Disclaimer

**Important**: This smart contract is for demonstration purposes. Before using in production:

- Conduct thorough security audits
- Implement proper legal compliance
- Add comprehensive testing
- Consider regulatory requirements for tokenized real estate
- Implement proper property valuation mechanisms

Real estate tokenization may be subject to securities regulations in your jurisdiction.