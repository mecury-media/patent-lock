# Patent-Lock: Blockchain IP Protection System

A comprehensive intellectual property registration and protection smart contract built on the Stacks blockchain using Clarity. Patent-Lock provides a decentralized solution for registering, licensing, and protecting various forms of intellectual property on-chain.

## 🚀 Features

### Core IP Management
- **Multi-type IP Support**: Register patents, trademarks, copyrights, and trade secrets
- **Content Hash Verification**: SHA256 hash-based authenticity verification
- **Duplicate Prevention**: Prevents multiple registrations of identical content
- **Automatic Expiry**: 10-year validity period with renewal options
- **Status Tracking**: Active, expired, and revoked status management

### Licensing System
- **Flexible License Types**: Exclusive, non-exclusive, and limited licenses
- **Royalty Management**: Configurable royalty rates up to 100%
- **Time-bound Licenses**: Set specific start and end periods
- **License Revocation**: Licensor can revoke licenses when needed
- **License Verification**: Check validity of licenses in real-time

### Dispute Resolution
- **Dispute Filing**: Challenge IP validity, ownership, or report infringement
- **Evidence Submission**: Submit evidence via content hashes
- **Resolution Process**: Contract owner can resolve disputes
- **Automatic Enforcement**: Upheld disputes result in IP revocation

### Security & Administration
- **Fee-based Registration**: STX payments for registration and renewal
- **Owner-only Functions**: Administrative controls for contract management
- **Emergency Controls**: Pause functionality for emergencies
- **Balance Management**: Withdraw accumulated fees

## 📋 Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- [Node.js](https://nodejs.org/) (v14 or higher)
- [Stacks CLI](https://docs.stacks.co/references/stacks-cli) (optional)

## 🛠️ Installation

1. **Clone the repository:**
```bash
git clone https://github.com/yourusername/patent-lock.git
cd patent-lock
```

2. **Initialize Clarinet project** (if not already done):
```bash
clarinet new patent-lock
cd patent-lock
```

3. **Add the contract:**
```bash
# Copy the patent-lock.clar file to contracts/ directory
cp path/to/patent-lock.clar contracts/
```

4. **Verify the contract:**
```bash
clarinet check
```

## 🔧 Configuration

### Contract Constants
```clarity
IP-REGISTRATION-FEE: 1000000 microSTX (1 STX)
IP-RENEWAL-FEE: 500000 microSTX (0.5 STX)
IP-VALIDITY-PERIOD: 52560000 blocks (~10 years)
```

### Supported IP Types
- `patent`: Utility and design patents
- `trademark`: Brand names and logos
- `copyright`: Creative works and software
- `trade-secret`: Confidential business information

## 📖 Usage

### Registering Intellectual Property

```clarity
(contract-call? .patent-lock register-ip
  "My Innovation Title"
  "Detailed description of the innovation"
  "patent"
  0x1234567890abcdef...  ;; SHA256 hash of content
  "Standard licensing terms"
)
```

### Granting a License

```clarity
(contract-call? .patent-lock grant-license
  u1              ;; IP ID
  'SP123...       ;; Licensee address
  "exclusive"     ;; License type
  u5256000        ;; Duration (1 year in blocks)
  u500            ;; 5% royalty rate
  "Custom terms"
)
```

### Transferring IP Ownership

```clarity
(contract-call? .patent-lock transfer-ip
  u1              ;; IP ID
  'SP456...       ;; New owner address
)
```

### Filing a Dispute

```clarity
(contract-call? .patent-lock file-dispute
  u1                        ;; IP ID
  "infringement"           ;; Dispute type
  0xabcdef1234567890...    ;; Evidence hash
)
```

## 🔍 Read-Only Functions

### Get IP Details
```clarity
(contract-call? .patent-lock get-ip-details u1)
```

### Check License Validity
```clarity
(contract-call? .patent-lock has-valid-license u1 'SP123...)
```

### Verify IP Authenticity
```clarity
(contract-call? .patent-lock verify-ip-authenticity u1 0x1234...)
```

### Get Contract Statistics
```clarity
(contract-call? .patent-lock get-contract-stats)
```

## 🧪 Testing

### Run Tests
```bash
clarinet test
```

### Console Testing
```bash
clarinet console
```

Example test session:
```clarity
>> (contract-call? .patent-lock register-ip "Test Patent" "Test Description" "patent" 0x123456 "Standard terms")
(ok u1)

>> (contract-call? .patent-lock get-ip-details u1)
(some {owner: ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM, title: "Test Patent", ...})
```

## 🏗️ Smart Contract Architecture

### Data Structures

#### IP Registry
```clarity
intellectual-properties: {
  ip-id: uint,
  owner: principal,
  title: string,
  description: string,
  ip-type: string,
  hash: buff,
  registration-block: uint,
  expiry-block: uint,
  status: string,
  license-terms: string
}
```

#### License Management
```clarity
ip-licenses: {
  ip-id: uint,
  licensee: principal,
  licensor: principal,
  license-type: string,
  start-block: uint,
  end-block: uint,
  royalty-rate: uint,
  terms: string,
  active: bool
}
```

#### Dispute System
```clarity
ip-disputes: {
  dispute-id: uint,
  ip-id: uint,
  challenger: principal,
  owner: principal,
  dispute-type: string,
  evidence-hash: buff,
  status: string,
  filed-block: uint,
  resolved-block: optional uint
}
```

### Error Codes
- `ERR-NOT-AUTHORIZED (u100)`: Unauthorized access
- `ERR-ALREADY-EXISTS (u101)`: IP already registered
- `ERR-NOT-FOUND (u102)`: IP not found
- `ERR-EXPIRED (u103)`: IP has expired
- `ERR-INVALID-PARAMETERS (u104)`: Invalid input parameters
- `ERR-TRANSFER-FAILED (u105)`: Transfer operation failed
- `ERR-INSUFFICIENT-PAYMENT (u106)`: Insufficient payment

## 🔐 Security Features

### Access Control
- Owner-only administrative functions
- IP owner verification for modifications
- License validation before operations

### Payment Security
- Required STX payments for registration and renewal
- Automatic fee collection to contract balance
- Owner-controlled balance withdrawal

### Data Integrity
- Content hash verification for authenticity
- Duplicate prevention system
- Immutable registration records

## 🚀 Deployment

### Testnet Deployment
```bash
clarinet deploy --testnet
```

### Mainnet Deployment
```bash
clarinet deploy --mainnet
```

## 📊 Gas Optimization

The contract is optimized for gas efficiency:
- Minimal storage operations
- Efficient map lookups
- Batched operations where possible
- Optimized data structures

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Create a Pull Request

### Development Guidelines
- Follow Clarity best practices
- Add comprehensive tests for new features
- Update documentation for API changes
- Ensure gas optimization

**Built with ❤️ using Clarity and Stacks blockchain technology**