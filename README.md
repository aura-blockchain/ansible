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
| `support_resync.yml` | Full resync from genesis |
| `support_prune.yml` | Prune chain data |

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

## License

MIT - See [LICENSE.md](LICENSE.md)

## Acknowledgments

- [Polkachu](https://polkachu.com/) for the validator playbook patterns
- [Cosmos SDK](https://cosmos.network/) community
