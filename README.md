# TenantChoice

TenantChoice is a collaborative voting system for building management and resident community policies built on the Stacks blockchain. This smart contract enables tenants to register, create proposals, and vote on building management decisions in a transparent and decentralized manner.

## Features

- **Tenant Registration**: Secure tenant registration with apartment number tracking
- **Proposal Creation**: Any registered tenant can create proposals for building decisions
- **Democratic Voting**: Simple majority voting system with transparent vote counting
- **Time-Limited Voting**: Configurable voting periods for each proposal
- **Vote Tracking**: Prevents double voting and maintains voting history
- **Proposal Management**: Automatic proposal closure after voting period ends
- **Administrative Controls**: Building owner can manage tenant registrations

## Technical Specifications

- **Blockchain**: Stacks
- **Smart Contract Language**: Clarity
- **Clarity Version**: 2
- **Epoch**: 2.5
- **Contract Size**: Lightweight and gas-efficient

## Project Structure

```
TenantChoice/
├── TenantChoice_contract/
│   ├── contracts/
│   │   └── TenantChoice.clar          # Main smart contract
│   ├── tests/
│   │   └── TenantChoice.test.ts       # Unit tests
│   ├── settings/
│   │   ├── Devnet.toml               # Development network config
│   │   ├── Testnet.toml              # Testnet configuration
│   │   └── Mainnet.toml              # Mainnet configuration
│   ├── Clarinet.toml                 # Clarinet project config
│   ├── package.json                  # Node.js dependencies
│   ├── tsconfig.json                 # TypeScript configuration
│   └── vitest.config.js              # Test configuration
└── README.md                         # This file
```

## Installation

### Prerequisites

- [Node.js](https://nodejs.org/) (v16 or later)
- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development toolkit

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd TenantChoice
```

2. Navigate to the contract directory:
```bash
cd TenantChoice_contract
```

3. Install dependencies:
```bash
npm install
```

4. Verify the contract compiles:
```bash
clarinet check
```

## Usage Examples

### Tenant Registration

```clarity
;; Register as a tenant with apartment number 101
(contract-call? .TenantChoice register-tenant u101)
```

### Creating a Proposal

```clarity
;; Create a proposal for building maintenance with 144 blocks voting duration (~24 hours)
(contract-call? .TenantChoice create-proposal
    "Install Security Cameras"
    "Proposal to install security cameras in main lobby and parking garage for enhanced building security"
    u144)
```

### Voting on Proposals

```clarity
;; Vote YES on proposal ID 1
(contract-call? .TenantChoice vote u1 true)

;; Vote NO on proposal ID 1
(contract-call? .TenantChoice vote u1 false)
```

### Checking Proposal Status

```clarity
;; Get proposal details
(contract-call? .TenantChoice get-proposal u1)

;; Check if proposal passed
(contract-call? .TenantChoice has-proposal-passed u1)

;; Get vote statistics
(contract-call? .TenantChoice get-vote-stats u1)
```

## Contract Functions

### Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `register-tenant` | Register a new tenant | `apartment-number: uint` |
| `deactivate-tenant` | Deactivate a tenant (owner only) | `tenant: principal` |
| `create-proposal` | Create a new proposal | `title: string-ascii 100`, `description: string-ascii 500`, `voting-duration: uint` |
| `vote` | Vote on a proposal | `proposal-id: uint`, `vote-choice: bool` |
| `close-proposal` | Close voting after period ends | `proposal-id: uint` |

### Read-Only Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `get-tenant` | Get tenant information | `tenant: principal` | Tenant data or none |
| `get-proposal` | Get proposal details | `proposal-id: uint` | Proposal data or none |
| `get-vote` | Get specific vote | `proposal-id: uint`, `voter: principal` | Vote choice or none |
| `has-proposal-passed` | Check if proposal passed | `proposal-id: uint` | Boolean |
| `get-total-tenants` | Get total registered tenants | None | uint |
| `get-next-proposal-id` | Get next proposal ID | None | uint |
| `is-voting-open` | Check if voting is open | `proposal-id: uint` | Boolean |
| `get-vote-stats` | Get vote statistics | `proposal-id: uint` | Vote counts object |

### Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `err-owner-only` | Function can only be called by contract owner |
| u101 | `err-not-tenant` | Caller is not a registered tenant |
| u102 | `err-already-registered` | Tenant is already registered |
| u103 | `err-proposal-not-found` | Proposal does not exist |
| u104 | `err-already-voted` | Tenant has already voted on this proposal |
| u105 | `err-voting-closed` | Voting period has ended |
| u106 | `err-invalid-proposal` | Invalid proposal parameters |
| u107 | `err-tenant-not-found` | Tenant not found in registry |

## Testing

Run the test suite:

```bash
npm test
```

Run tests with coverage and cost analysis:

```bash
npm run test:report
```

Watch for changes and run tests automatically:

```bash
npm run test:watch
```

## Deployment Guide

### Development Network (Devnet)

1. Start local devnet:
```bash
clarinet integrate
```

2. Deploy the contract:
```bash
clarinet deploy --devnet
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`

2. Deploy to testnet:
```bash
clarinet deploy --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`

2. Deploy to mainnet:
```bash
clarinet deploy --mainnet
```

## Security Notes

### Access Control
- Only the contract owner can deactivate tenants
- Only registered, active tenants can create proposals and vote
- Tenants cannot vote twice on the same proposal

### Voting Integrity
- Votes are recorded on-chain and immutable
- Voting periods are enforced by block height
- Simple majority determines proposal outcome

### Data Validation
- Proposal titles and descriptions have length limits
- Apartment numbers and voting durations must be positive
- All inputs are validated before execution

### Recommendations
- Carefully manage the contract owner principal
- Consider implementing proposal categories or minimum participation thresholds
- Monitor gas costs for large tenant populations
- Implement off-chain notification systems for proposal updates

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the ISC License.

## Support

For questions or issues, please open an issue in the repository or contact the development team.