#!/bin/bash
# AURA automatic health check - runs daily
# Install: crontab -e -> 0 8 * * * /path/to/auto-health-check.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(dirname "$SCRIPT_DIR")"
INVENTORY="$ANSIBLE_DIR/inventory/testnet.yml"
LOG_DIR="$ANSIBLE_DIR/logs"
LOG_FILE="$LOG_DIR/health-$(date +%Y%m%d).log"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting AURA daily health check..."

# Run health check playbook
if ansible-playbook -i "$INVENTORY" "$ANSIBLE_DIR/playbooks/health-check.yml" >> "$LOG_FILE" 2>&1; then
    log "Health check passed"
else
    log "ERROR: Health check failed - review $LOG_FILE"
fi

# Check disk space on AURA servers
log "Checking disk space..."
for server in aura-testnet services-testnet; do
    usage=$(ssh -o ConnectTimeout=10 "$server" "df -h / | tail -1 | awk '{print \$5}' | tr -d '%'" 2>/dev/null || echo "ERROR")
    if [[ "$usage" == "ERROR" ]]; then
        log "  $server: Unable to connect"
    elif [[ "$usage" -gt 80 ]]; then
        log "  WARNING: $server disk usage at ${usage}%"
    else
        log "  $server: ${usage}% disk used"
    fi
done

# Clean up old logs (keep 30 days)
find "$LOG_DIR" -name "health-*.log" -mtime +30 -delete 2>/dev/null || true

log "Health check complete"
