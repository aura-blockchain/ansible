# Contributing to AURA

Thank you for contributing to AURA! This guide covers our development workflow and standards.

## Code of Conduct

By participating, you agree to maintain a respectful and inclusive environment. See `CODE_OF_CONDUCT.md` for details.

## Reporting Bugs

- Search existing issues to avoid duplicates
- Include steps to reproduce and system information (OS, Go version)
- For security vulnerabilities, see `SECURITY.md` for private disclosure

## Submitting Pull Requests

1. Fork and create a feature branch: `git checkout -b feature/your-feature`
2. Make changes following code style guidelines
3. Run tests: `make test && make lint`
4. Commit with conventional format (see below)
5. Push and create PR, address review feedback

## Development Setup

```bash
git clone https://github.com/YOUR_USERNAME/aura.git && cd aura
cd chain
go mod download
make build
./build/aurad version
```

### Pre-commit Hooks (Recommended)

```bash
pip install pre-commit
pre-commit install
```

## Code Style

### Go
- Follow [Effective Go](https://golang.org/doc/effective_go) and [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- Use `gofmt`, `goimports`, and `golangci-lint`
- Avoid `panic()` in production; return errors
- Never use `sdk.MustAccAddressFromBech32` in production paths

### Protobuf
- Include comprehensive field documentation
- Run `make proto-gen` after changes
- Follow Cosmos SDK proto conventions

## Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `security`

**Scopes** (AURA-specific):
- `identity` - Identity module changes
- `compliance` - Compliance and KYC module
- `privacy` - Privacy-preserving features
- `governance` - Governance module
- `exchange` - Exchange functionality
- `chain` - Core chain changes

**Examples**:
- `feat(identity): add DID document verification`
- `fix(compliance): correct jurisdiction validation`
- `security(privacy): enhance credential encryption`

## Testing Requirements

### Required for All PRs
- Unit tests for new functions
- Integration tests for module changes
- Table-driven tests where appropriate

### Module Development
1. Update protobuf definitions in `proto/`
2. Regenerate: `make proto-gen`
3. Implement keeper methods with error handling
4. Add/update genesis import/export
5. Write comprehensive tests
6. Update documentation in `docs/`

### Running Tests

```bash
cd chain
make test           # Unit tests
make test-cover     # With coverage report
make lint           # Linter checks
```

### Coverage Standards
- Minimum 80% for new code
- 100% for security-critical paths (identity, compliance, privacy modules)

## Branch Strategy

```
main              - Production-ready, protected
develop           - Integration branch
feature/xyz       - Individual features
hotfix/xyz        - Emergency fixes
release/v1.0.0    - Release candidates
```

### Protected Branch Rules
- `main` requires PR with 2+ approvals
- All CI checks must pass
- No force pushes

## Pull Request Process

1. Ensure tests pass and linters are clean
2. Update documentation for user-facing changes
3. Add changelog entry if applicable
4. Request review from code owners (auto-assigned via CODEOWNERS)
5. Address feedback and squash commits if requested

### PR Categories Requiring Extra Review

| Category | Required Reviewers |
|----------|-------------------|
| Consensus changes | 2+ senior devs |
| State migrations | Core team + ops |
| Identity/compliance | Security team |
| Privacy module | Cryptography reviewer |

## Security

- Never commit secrets or credentials
- Run `gosec ./...` before submitting
- Follow Cosmos SDK security best practices
- Report vulnerabilities privately (see `SECURITY.md`)

## DCO Sign-off

All commits must be signed off to certify you have the right to submit the work:

```bash
git commit -s -m "feat(identity): your feature description"
```

This adds a `Signed-off-by:` line certifying agreement with the [Developer Certificate of Origin](https://developercertificate.org/).

### Configuring Git for Sign-off

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Amending Unsigned Commits

```bash
git commit --amend -s
```

## Questions?

- GitHub Discussions for general questions
- Documentation in `docs/`
- `SECURITY.md` for security-related questions

## License

Contributions are licensed under the Apache License 2.0 (see LICENSE file).
