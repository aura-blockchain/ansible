#!/bin/bash
#
# AURA Testnet Deployment Script
# Wrapper for ansible-playbook with common options
#
# Usage:
#   ./deploy.sh                     # Full deployment
#   ./deploy.sh --check             # Dry run (no changes)
#   ./deploy.sh --tags security     # Only security tasks
#   ./deploy.sh --limit aura-testnet # Single host
#   ./deploy.sh --tags node_exporter --limit validators
#
# Examples:
#   # Deploy monitoring stack only
#   ./deploy.sh --tags monitoring,prometheus,grafana
#
#   # Update firewall rules (dry run first)
#   ./deploy.sh --tags firewall --check
#   ./deploy.sh --tags firewall
#
#   # Deploy to validators only
#   ./deploy.sh --limit validators
#
#   # Full security hardening
#   ./deploy.sh --tags security,firewall,wireguard
#
#   # Update node exporters on all nodes
#   ./deploy.sh --tags node_exporter,cosmos_exporter
#
#   # Deploy health checks
#   ./deploy.sh --tags health
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for ansible
if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${RED}Error: ansible-playbook not found${NC}"
    echo "Install Ansible with: pip install ansible>=2.15"
    exit 1
fi

# Check ansible version
ANSIBLE_VERSION=$(ansible --version | head -n1 | grep -oP '\d+\.\d+')
REQUIRED_VERSION="2.15"
if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$ANSIBLE_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo -e "${YELLOW}Warning: Ansible version $ANSIBLE_VERSION may be too old. Recommended: >= $REQUIRED_VERSION${NC}"
fi

# Install galaxy requirements if needed
if [ ! -d "$HOME/.ansible/collections/ansible_collections/ansible/posix" ] || \
   [ ! -d "$HOME/.ansible/collections/ansible_collections/community/general" ]; then
    echo -e "${YELLOW}Installing Ansible Galaxy requirements...${NC}"
    ansible-galaxy collection install -r requirements.yml
fi

# Create cache directory
mkdir -p .ansible_cache

# Parse arguments
TAGS=""
LIMIT=""
CHECK=""
EXTRA_ARGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --tags|-t)
            TAGS="--tags $2"
            shift 2
            ;;
        --limit|-l)
            LIMIT="--limit $2"
            shift 2
            ;;
        --check|-C)
            CHECK="--check"
            shift
            ;;
        --diff|-D)
            EXTRA_ARGS="$EXTRA_ARGS --diff"
            shift
            ;;
        --verbose|-v|-vv|-vvv|-vvvv)
            EXTRA_ARGS="$EXTRA_ARGS $1"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --tags, -t TAGS    Run only tasks with these tags"
            echo "  --limit, -l HOST   Limit to specific hosts/groups"
            echo "  --check, -C        Dry run (no changes made)"
            echo "  --diff, -D         Show differences in changed files"
            echo "  --verbose, -v      Increase verbosity (-vvv for more)"
            echo "  --help, -h         Show this help message"
            echo ""
            echo "Available tags:"
            echo "  common          - Base system configuration"
            echo "  security        - Security hardening"
            echo "  firewall        - UFW firewall rules"
            echo "  wireguard       - WireGuard VPN setup"
            echo "  monitoring      - All monitoring components"
            echo "  node_exporter   - Prometheus node exporter"
            echo "  cosmos_exporter - Cosmos-specific metrics"
            echo "  tenderduty      - Validator monitoring"
            echo "  alertmanager    - Alert routing"
            echo "  promtail        - Log shipping to Loki"
            echo "  logging         - Centralized logging"
            echo "  snapshot        - Snapshot automation"
            echo "  health          - Health check daemons"
            exit 0
            ;;
        *)
            EXTRA_ARGS="$EXTRA_ARGS $1"
            shift
            ;;
    esac
done

# Build command
CMD="ansible-playbook aura-playbook.yml $TAGS $LIMIT $CHECK $EXTRA_ARGS"

echo -e "${GREEN}Running: $CMD${NC}"
echo ""

# Execute
exec $CMD
