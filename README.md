# Blockchain-Verified Organic Food Certification

A decentralized platform for verifying and certifying organic food production using blockchain technology. This system ensures transparency, traceability, and trust in the organic food supply chain.

## Overview

This Clarinet project implements smart contracts for blockchain-verified organic food certification. The system provides immutable records of farm validation, organic certification, and supply chain tracking to ensure consumers can trust the authenticity of organic food products.

## Architecture

The system consists of two main smart contracts:

### 1. Farm Validator Contract (`farm-validator.clar`)
- Manages farm registration and validation
- Tracks farm certifications and compliance status
- Handles validator assignments and ratings
- Maintains farm production records

### 2. Organic Registry Contract (`organic-registry.clar`)
- Registers organic products and their certifications
- Tracks product lifecycle from farm to consumer
- Manages certification authorities and standards
- Provides product verification endpoints

## Key Features

- **Decentralized Farm Validation**: Independent validators can assess and certify farms
- **Immutable Certification Records**: All certifications are permanently recorded on the blockchain
- **Supply Chain Tracking**: Complete traceability from farm to consumer
- **Multi-Authority Support**: Support for multiple certification bodies and standards
- **Consumer Verification**: Easy verification of product authenticity by end consumers

## Smart Contract Functions

### Farm Validator
- `register-farm`: Register a new farm in the system
- `validate-farm`: Submit farm validation results
- `update-farm-status`: Update farm certification status
- `get-farm-info`: Retrieve farm information and certification status

### Organic Registry
- `register-product`: Register a new organic product
- `certify-product`: Add certification to a product
- `track-product`: Update product location in supply chain
- `verify-product`: Verify product authenticity and certifications

## Getting Started

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) installed
- [Node.js](https://nodejs.org/) for testing and development tools
- Basic understanding of Clarity smart contract language

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd blockchain-verified-organic-food-certification
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Verify contracts:
   ```bash
   clarinet check
   ```

### Development

#### Running Tests

```bash
npm test
```

#### Contract Validation

```bash
clarinet check
```

#### Local Development Network

```bash
clarinet console
```

## Configuration

Configuration files are located in the `settings/` directory:

- `Devnet.toml`: Local development configuration
- `Testnet.toml`: Testnet deployment configuration  
- `Mainnet.toml`: Production configuration

## Testing

The project includes comprehensive tests for all contract functions:

- Unit tests for individual contract functions
- Integration tests for cross-contract interactions
- Edge case and error condition testing

Run tests with:
```bash
npm run test
```

## Deployment

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy contracts:
   ```bash
   clarinet publish --testnet
   ```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`
2. Deploy contracts:
   ```bash
   clarinet publish --mainnet
   ```

## API Documentation

### Farm Validator API

| Function | Parameters | Returns | Description |
|----------|------------|---------|-------------|
| `register-farm` | `farm-id`, `owner`, `location` | `Response` | Register new farm |
| `validate-farm` | `farm-id`, `validator`, `score` | `Response` | Submit validation |
| `get-farm-info` | `farm-id` | `Farm Details` | Get farm information |

### Organic Registry API

| Function | Parameters | Returns | Description |
|----------|------------|---------|-------------|
| `register-product` | `product-id`, `farm-id`, `details` | `Response` | Register product |
| `certify-product` | `product-id`, `authority`, `standard` | `Response` | Add certification |
| `verify-product` | `product-id` | `Verification Result` | Verify authenticity |

## Security Considerations

- All critical functions require proper authorization
- Input validation is implemented for all parameters
- Access control mechanisms protect sensitive operations
- Audit logs are maintained for all transactions

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Make your changes and add tests
4. Verify all tests pass: `npm test`
5. Submit a pull request

### Development Guidelines

- Follow Clarity coding standards
- Include comprehensive tests for new features
- Update documentation for any API changes
- Ensure all contracts pass `clarinet check`

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions and support:
- Create an issue in the GitHub repository
- Join our community discussion forum
- Check the documentation at [docs.hiro.so/clarinet](https://docs.hiro.so/clarinet)

## Roadmap

- [ ] Mobile app integration
- [ ] QR code product verification
- [ ] Multi-language certification support
- [ ] Advanced analytics dashboard
- [ ] Integration with IoT sensors

---

*Built with ❤️ using Clarinet and the Stacks blockchain*
