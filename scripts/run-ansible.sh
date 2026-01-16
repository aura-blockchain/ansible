#!/bin/bash
# AURA Ansible runner
# Usage: ./run-ansible.sh <command>
#
# Commands:
#   deploy         - Deploy all AURA validators
#   update         - Rolling binary update
#   health         - Health check all validators
#   rollback       - Rollback to previous version
#   backup         - Backup validator keys

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(dirname "$SCRIPT_DIR")"
INVENTORY="$ANSIBLE_DIR/inventory/testnet.yml"
PLAYBOOKS="$ANSIBLE_DIR/playbooks"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_help() {
    cat << EOF
AURA Ansible Runner

Usage: $0 <command> [options]

Commands:
  deploy              Deploy all AURA validators
  deploy-services     Deploy AURA supporting services
  update <binary>     Rolling binary update
                      binary: path to new aurad binary
  health              Health check all validators
  rollback            Rollback to previous binary version
  backup              Backup validator keys (STORE SECURELY!)
  check               Dry-run to see what would change

Options:
  --limit <val>       Target specific validator (aura_val1, aura_val2, etc.)

Examples:
  $0 deploy                       Deploy all AURA validators
  $0 update ./aurad               Update binary on all validators
  $0 update ./aurad --limit aura_val1   Update single validator
  $0 health                       Check all validators
  $0 rollback                     Rollback all validators

EOF
}

run_playbook() {
    local playbook=$1
    shift
    log_info "Running: ansible-playbook -i $INVENTORY $playbook $*"
    ansible-playbook -i "$INVENTORY" "$playbook" "$@"
}

case "${1:-help}" in
    deploy)
        shift
        log_info "Deploying AURA validators..."
        run_playbook "$PLAYBOOKS/deploy-validators.yml" "$@"
        ;;

    deploy-services)
        shift
        log_info "Deploying AURA services..."
        run_playbook "$PLAYBOOKS/deploy-services.yml" "$@"
        ;;

    update)
        shift
        binary="$1"
        shift || true
        if [[ -z "$binary" ]]; then
            log_error "Usage: $0 update <binary_path> [--limit validator]"
            exit 1
        fi
        if [[ ! -f "$binary" ]]; then
            log_error "Binary not found: $binary"
            exit 1
        fi
        log_info "Rolling binary update with $binary..."
        run_playbook "$PLAYBOOKS/update-binaries.yml" -e "local_binary_path=$binary" "$@"
        ;;

    health)
        shift
        log_info "Running health checks..."
        run_playbook "$PLAYBOOKS/health-check.yml" "$@"
        ;;

    rollback)
        shift
        log_warn "Rolling back AURA validators to previous version..."
        read -p "Are you sure? (y/N) " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            run_playbook "$PLAYBOOKS/rollback.yml" "$@"
        else
            log_info "Rollback cancelled"
        fi
        ;;

    backup)
        shift
        log_warn "Backing up AURA validator keys..."
        log_warn "IMPORTANT: Secure these files immediately after backup!"
        run_playbook "$PLAYBOOKS/backup-keys.yml" "$@"
        ;;

    check)
        shift
        log_info "Dry-run check (no changes will be made)..."
        run_playbook "$PLAYBOOKS/deploy-validators.yml" --check --diff "$@"
        ;;

    help|--help|-h)
        show_help
        ;;

    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac

log_info "Done!"
