# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| main branch | Yes |
| testnet releases | Yes |
| < v1.0 | No |

## Reporting a Vulnerability

**DO NOT** create public GitHub issues for security vulnerabilities.

### Contact
- **Email**: security@aurablockchain.org
- **Response Time**: 48 hours for initial acknowledgment
- **Disclosure Policy**: 90-day coordinated disclosure

### What to Include
- Affected component and file paths
- Step-by-step reproduction instructions
- Proof of concept (if available)
- Impact assessment
- Suggested fix (optional)

## Scope

### In Scope
- Core blockchain node (`chain/`)
- Cosmos SDK modules (`chain/x/`)
- Smart contract integration (`contracts/`)
- Cryptographic implementations
- IBC handlers
- Genesis and upgrade handlers

### Out of Scope
- Third-party dependencies (report upstream)
- Documentation and website
- Denial-of-service against public testnet
- Social engineering attacks
- Issues already reported or known

## Security Model

### Trust Assumptions
1. **Validator Set**: 2/3+ honest validators (Byzantine fault tolerance)
2. **Cryptographic Primitives**: Ed25519, SHA-256 (standard Cosmos SDK)
3. **Consensus**: CometBFT with standard BFT guarantees
4. **Go Runtime**: Relies on Go's memory safety

### Module Security
- **Credential Verification**: Core AURA functionality for verifiable credentials
- **WASM Contracts**: Sandboxed execution with gas metering
- **Governance**: Standard Cosmos SDK x/gov module

## Bug Bounty Program

**Status**: Planned for mainnet

| Severity | Planned Reward |
|----------|----------------|
| Critical | Up to $25,000 |
| High | Up to $10,000 |
| Medium | Up to $2,500 |
| Low | Up to $500 |

### Severity Guidelines
- **Critical**: Network halt, fund theft, consensus failure
- **High**: State corruption, significant fund loss
- **Medium**: Limited impact bugs, DoS vectors
- **Low**: Minor issues, edge cases

## Audit History

| Date | Auditor | Scope | Status |
|------|---------|-------|--------|
| TBD | TBD | Full Protocol | Pending |

## Security Checklist

- [x] Apache 2.0 license
- [x] Security contact established
- [x] Code of conduct in place
- [x] Signed commits required
- [ ] External security audit
- [ ] Bug bounty program launched
- [ ] Incident response plan documented

## Contact

For security inquiries: security@aurablockchain.org
