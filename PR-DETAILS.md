# Add organic food certification contracts

## Overview

This pull request introduces two core smart contracts for the blockchain-verified organic food certification system:

- **Farm Validator Contract** - Manages farm registration, validation, and certification
- **Organic Registry Contract** - Handles product registration, certification, and supply chain tracking

## Implementation Details

### Farm Validator Contract (299 lines)
- Farm registration and management system
- Validator registration and reputation tracking
- Comprehensive validation scoring system
- Farm status management

### Organic Registry Contract (387 lines)
- Product registration with batch tracking
- Multi-authority certification system
- Supply chain movement tracking
- Product authenticity verification

## Technical Validation

Contract validation passed successfully:
```
$ clarinet check
✔ 2 contracts checked
```

## Standards Support

- USDA Organic
- EU Organic
- JAS Organic (Japan)  
- Biodynamic
- Rainforest Alliance

## Security Features

- Authorization controls for all sensitive operations
- Comprehensive input validation
- Proper state management
- Access control mechanisms

---

**Ready for review and deployment.**
