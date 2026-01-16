# AURA Ansible Quick Reference

## Daily Operations

### Check All Validators
```bash
ansible-playbook -i inventory/testnet.yml playbooks/health-check.yml
```

### Update Binary (Rolling)
```bash
# 1. Build locally
cd ~/blockchain-projects/aura-project/aura && make build

# 2. Deploy via Ansible
cd ~/blockchain-projects/aura-project/infra/ansible
ansible-playbook -i inventory/testnet.yml playbooks/update-binaries.yml \
  -e "local_binary_path=../../aura/build/aurad"
```

### Rollback (If Something Breaks)
```bash
ansible-playbook -i inventory/testnet.yml playbooks/rollback.yml
```

## Targeting Validators

```bash
# All validators
--limit validators

# Primary server (val1, val2)
--limit primary_validators

# Secondary server (val3, val4)
--limit secondary_validators

# Single validator
--limit aura_val1
```

## When Things Go Wrong

### Node Won't Start
```bash
# Check status
ssh aura-testnet "sudo systemctl status aurad-val1"

# View logs
ssh aura-testnet "journalctl -u aurad-val1 -n 100"

# Rollback single validator
ansible-playbook -i inventory/testnet.yml playbooks/rollback.yml --limit aura_val1
```

### Can't Connect to Server
```bash
ssh aura-testnet        # Primary
ssh services-testnet    # Secondary
```

## Backup Keys
```bash
ansible-playbook -i inventory/testnet.yml playbooks/backup-keys.yml
# Keys saved to /tmp/aura-keys-backup-<date>/
```

## Manual Service Control
```bash
# On aura-testnet
sudo systemctl status aurad-val1
sudo systemctl status aurad-val2

# On services-testnet
sudo systemctl status aurad-val3
sudo systemctl status aurad-val4
```
