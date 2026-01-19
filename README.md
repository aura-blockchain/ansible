# AURA Validator Infrastructure

Ansible playbooks for deploying and managing AURA blockchain validators, sentries, and supporting infrastructure.

Based on [Polkachu's cosmos-validators](https://github.com/polkachu/cosmos-validators) patterns.

## Features

- Multi-node validator deployment with sentry architecture
- Cosmovisor for automated upgrades
- Security hardening (SSH, fail2ban, UFW)
- Prometheus monitoring stack (node_exporter, cosmos_exporter)
- Tenderduty validator alerting
- Automated snapshots and state-sync
- WireGuard VPN for private validator network

## Quick Start

```bash
# Install dependencies
pip install ansible>=2.15
ansible-galaxy install -r requirements.yml

# Deploy (dry run first)
ansible-playbook -i inventory/testnet.yml main.yml --check --diff

# Full deployment
ansible-playbook -i inventory/testnet.yml main.yml
```

## Playbooks

| Playbook | Description |
|----------|-------------|
| `main.yml` | Full node deployment |
| `setup.yml` | Initial server setup |
| `support_backup_keys.yml` | Backup validator keys |
| `support_restore_keys.yml` | Restore validator keys |
| `support_migrate_node.yml` | Migrate node to new server |
| `support_remove_node.yml` | Decommission a node |
| `support_monitoring.yml` | Deploy monitoring stack |
| `support_snapshot.yml` | Create chain snapshot |
| `support_sync_snapshot.yml` | Sync from snapshot |
| `support_state_sync.yml` | State-sync from peers |
| `support_genesis_sync.yml` | Full sync from genesis (archive node) |
| `support_resync.yml` | Reset and resync (keeps genesis) |
| `support_prune.yml` | Prune chain data |
| `support_enforce_hermit_rules.yml` | Enforce validator/sentry hermit rules |

## Roles

| Role | Description |
|------|-------------|
| `common` | Base packages, users, directories |
| `security` | SSH hardening, fail2ban, limits |
| `node` | Cosmos SDK node with Cosmovisor |
| `nginx` | Reverse proxy with TLS, CORS, rate limiting |
| `monitoring` | Prometheus server |
| `node_exporter` | System metrics |
| `cosmos_exporter` | Chain metrics |
| `tenderduty` | Validator alerting |
| `snapshot` | Automated snapshots |
| `wireguard` | VPN configuration |

## Directory Structure

```
├── main.yml                 # Main deployment playbook
├── setup.yml                # Initial server setup
├── support_*.yml            # Operational playbooks
├── inventory/
│   └── testnet.yml          # Host inventory
├── group_vars/
│   ├── all.yml              # Global variables
│   └── validators.yml       # Validator-specific vars
├── roles/                   # Ansible roles
└── files/                   # Static files (dashboards, alerts)
```

## Configuration

### Inventory

Edit `inventory/testnet.yml` to define your hosts:

```yaml
all:
  children:
    validators:
      hosts:
        val1:
          ansible_host: 1.2.3.4
          node_type: validator
    sentries:
      hosts:
        sentry1:
          ansible_host: 5.6.7.8
          node_type: sentry
```

### Variables

Key variables in `group_vars/all.yml`:

```yaml
chain_id: "aura-mvp-1"
chain_binary: "aurad"
go_version: "1.21.6"
```

## Usage Examples

```bash
# Deploy to specific host
ansible-playbook -i inventory/testnet.yml main.yml --limit val1

# Run specific tags
ansible-playbook -i inventory/testnet.yml main.yml --tags monitoring

# Create snapshot
ansible-playbook -i inventory/testnet.yml support_snapshot.yml --limit val1

# State-sync a new node
ansible-playbook -i inventory/testnet.yml support_state_sync.yml --limit sentry1
```

## Requirements

- Ansible 2.15+
- Python 3.10+
- SSH access to target servers
- Target servers: Ubuntu 22.04/24.04

## Validator/Sentry Hermit Rules

This infrastructure follows the validator/sentry hermit architecture defined in `blockchain-projects/shared/cosmos-validator-and-sentry-rules.txt`:

**Validators (hermit mode):**
- `pex = false` - Do not discover public peers
- `persistent_peers` - Only connect to trusted sentries
- `addr_book_strict = false` - Allow private IP connections
- API/gRPC disabled, RPC bound to localhost only

**Sentries (public-facing):**
- `pex = true` - Discover public peers for block gossip
- `persistent_peers` - All validators + other sentries
- `private_peer_ids` - All validator node IDs (never gossip them)
- API/gRPC/RPC publicly accessible

Use `support_enforce_hermit_rules.yml` to verify and enforce these rules:

```bash
# Dry run (check compliance without changes)
ansible-playbook -i inventory/testnet.yml support_enforce_hermit_rules.yml --check

# Enforce rules
ansible-playbook -i inventory/testnet.yml support_enforce_hermit_rules.yml
```

## License

MIT - See [LICENSE.md](LICENSE.md)

## Acknowledgments

- [Polkachu](https://polkachu.com/) for the validator playbook patterns
- [Cosmos SDK](https://cosmos.network/) community
