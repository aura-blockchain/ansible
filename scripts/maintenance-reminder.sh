#!/bin/bash
# AURA Maintenance reminder - runs monthly
# Install: crontab -e -> 0 9 1 * * /path/to/maintenance-reminder.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$ANSIBLE_DIR/logs/maintenance.log"
LAST_RUN_FILE="$ANSIBLE_DIR/.last_maintenance"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=========================================="
log "AURA Monthly Maintenance Reminder"
log "=========================================="

# Check when Ansible was last run
if [[ -f "$LAST_RUN_FILE" ]]; then
    last_run=$(cat "$LAST_RUN_FILE")
    days_since=$(( ($(date +%s) - $(date -d "$last_run" +%s)) / 86400 ))
    log "Last Ansible run: $last_run ($days_since days ago)"

    if [[ $days_since -gt 30 ]]; then
        log "WARNING: Ansible hasn't been run in over 30 days!"
    fi
else
    log "WARNING: No record of previous Ansible runs"
fi

log ""
log "MAINTENANCE CHECKLIST:"
log "----------------------"
log "[ ] Check for Go updates (current: 1.22.x)"
log "[ ] Check for Cosmos SDK updates"
log "[ ] Check for CometBFT updates"
log "[ ] Review security advisories"
log "[ ] Verify backups are current"
log "[ ] Check disk space on AURA servers"
log "[ ] Review Prometheus alerts"
log "[ ] Test disaster recovery procedures"
log ""
log "QUICK COMMANDS:"
log "---------------"
log "Health check:    $SCRIPT_DIR/run-ansible.sh health"
log "Check changes:   $SCRIPT_DIR/run-ansible.sh check"
log "Deploy all:      $SCRIPT_DIR/run-ansible.sh deploy"
log ""

# Check server connectivity
log "Checking AURA server connectivity..."
for server in aura-testnet services-testnet; do
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$server" exit 2>/dev/null; then
        log "  ✓ $server - OK"
    else
        log "  ✗ $server - UNREACHABLE"
    fi
done

log ""
log "Reminder complete. Review the checklist above."
