# AURA Testnet Ansible Deployment

Ansible playbooks for deploying and managing the AURA testnet infrastructure.

## Prerequisites

- Ansible 2.15 or newer
- SSH access to target servers (hudson@)
- SOPS + age for secrets decryption

### Install Ansible

```bash
pip install ansible>=2.15
```

### Install Galaxy Collections

```bash
ansible-galaxy install -r requirements.yml
```

Or let the deploy script handle it automatically.

## Quick Start

```bash
# Full deployment (all hosts, all tasks)
./deploy.sh

# Dry run first (recommended)
./deploy.sh --check

# Show what would change
./deploy.sh --check --diff
```

## Common Commands

```bash
# Deploy to a single server
./deploy.sh --limit aura-testnet

# Deploy only security configurations
./deploy.sh --tags security

# Update monitoring stack
./deploy.sh --tags monitoring

# Deploy firewall rules only
./deploy.sh --tags firewall

# Update node exporters on validators
./deploy.sh --tags node_exporter --limit validators

# Full security hardening
./deploy.sh --tags security,firewall,wireguard

# Verbose output for debugging
./deploy.sh -vvv
```

## Available Tags

| Tag | Description |
|-----|-------------|
| `common` | Base system packages, users, directories |
| `security` | SSH hardening, fail2ban, security limits |
| `firewall` | UFW firewall rules |
| `wireguard` | WireGuard VPN configuration |
| `monitoring` | All monitoring components |
| `node_exporter` | Prometheus node exporter |
| `cosmos_exporter` | Cosmos-specific metrics exporter |
| `tenderduty` | Validator monitoring and alerting |
| `alertmanager` | Prometheus Alertmanager |
| `promtail` | Log shipping to Loki |
| `logging` | Centralized logging configuration |
| `snapshot` | Automated snapshot scripts |
| `health` | Health check daemons |

## Directory Structure

```
ansible/
├── ansible.cfg           # Ansible configuration
├── requirements.yml      # Galaxy collection dependencies
├── deploy.sh             # Deployment wrapper script
├── site.yml              # Main playbook
├── inventory/
│   └── testnet.yml       # Host inventory
├── group_vars/
│   ├── all.yml           # Variables for all hosts
│   ├── validators.yml    # Validator-specific vars
│   └── sentries.yml      # Sentry-specific vars
├── host_vars/
│   ├── aura-testnet.yml  # Per-host variables
│   └── services-testnet.yml
├── roles/
│   ├── common/           # Base system setup
│   ├── security/         # Security hardening
│   ├── firewall/         # UFW configuration
│   ├── wireguard/        # VPN setup
│   ├── cosmos_node/      # Cosmos node deployment
│   ├── monitoring/       # Prometheus, Grafana
│   ├── node_exporter/    # Prometheus node exporter
│   ├── cosmos_exporter/  # Cosmos metrics
│   ├── tenderduty/       # Validator monitoring
│   ├── promtail/         # Log shipping
│   └── health/           # Health checks
└── .ansible_cache/       # Fact cache (gitignored)
```

## SOPS Integration

Sensitive variables are encrypted with SOPS. The playbooks expect decrypted values to be available at runtime.

### Decrypt secrets for use

```bash
export SOPS_AGE_KEY_FILE=~/.config/sops/age/aura/keys.txt
sops -d ../../secrets/testnet.yaml
```

### Use in playbooks

Secrets should be loaded via `lookup` or pre-decrypted environment variables:

```yaml
# In group_vars/all.yml
cloudflare_api_token: "{{ lookup('env', 'CLOUDFLARE_API_TOKEN') }}"
```

Or use the SOPS lookup plugin:

```yaml
cloudflare_api_token: "{{ lookup('community.sops.sops', '../../secrets/testnet.yaml', extract='cloudflare.api_token') }}"
```

## Host Groups

| Group | Hosts | Description |
|-------|-------|-------------|
| `validators` | aura-testnet, services-testnet | Validator nodes |
| `sentries` | aura-testnet, services-testnet | Sentry nodes |
| `all` | All hosts | Every server |

## Troubleshooting

### Connection Issues

```bash
# Test connectivity
ansible all -m ping

# Test with verbose output
ansible all -m ping -vvv

# Test specific host
ansible aura-testnet -m ping
```

### SSH Key Issues

```bash
# Verify SSH key
ssh -i ~/.ssh/id_ed25519 hudson@158.69.119.76

# Check ansible.cfg
cat ansible.cfg | grep private_key_file
```

### Galaxy Collection Missing

```bash
# Force reinstall collections
ansible-galaxy collection install -r requirements.yml --force
```

### Fact Cache Issues

```bash
# Clear fact cache
rm -rf .ansible_cache/*

# Disable caching temporarily
ANSIBLE_CACHE_PLUGIN=memory ./deploy.sh
```

### Check Mode Differences

```bash
# See what would change without applying
./deploy.sh --check --diff

# Verbose check mode
./deploy.sh --check --diff -vv
```

## Server Information

| Server | SSH Alias | Public IP | VPN IP |
|--------|-----------|-----------|--------|
| aura-testnet | `ssh aura-testnet` | 158.69.119.76 | 10.10.0.1 |
| services-testnet | `ssh services-testnet` | 139.99.149.160 | 10.10.0.4 |

## Related Documentation

- [AURA Testnet Architecture](../../docs/architecture.md)
- [Secrets Management](../../secrets/README.md)
- [Monitoring Stack](../monitoring/README.md)
