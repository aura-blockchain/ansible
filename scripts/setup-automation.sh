#!/bin/bash
# Set up automated maintenance tasks
# Run once: ./setup-automation.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up automated maintenance tasks..."

# Make scripts executable
chmod +x "$SCRIPT_DIR/run-ansible.sh"
chmod +x "$SCRIPT_DIR/maintenance-reminder.sh"
chmod +x "$SCRIPT_DIR/auto-health-check.sh"

# Create logs directory
mkdir -p "$SCRIPT_DIR/../logs"

# Add cron jobs
CRON_ENTRIES=$(cat << EOF
# Blockchain Infrastructure Automation
# Daily health check at 8am
0 8 * * * $SCRIPT_DIR/auto-health-check.sh >> $SCRIPT_DIR/../logs/cron.log 2>&1

# Monthly maintenance reminder on the 1st at 9am
0 9 1 * * $SCRIPT_DIR/maintenance-reminder.sh >> $SCRIPT_DIR/../logs/cron.log 2>&1

# Weekly security updates check on Sunday at 10am
0 10 * * 0 apt list --upgradable 2>/dev/null | grep -i security >> $SCRIPT_DIR/../logs/security-updates.log 2>&1
EOF
)

echo ""
echo "The following cron entries will be added:"
echo "=========================================="
echo "$CRON_ENTRIES"
echo "=========================================="
echo ""
read -p "Add these to crontab? (y/N) " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    # Backup existing crontab
    crontab -l > /tmp/crontab.backup 2>/dev/null || true

    # Add new entries (avoiding duplicates)
    (crontab -l 2>/dev/null | grep -v "Blockchain Infrastructure" | grep -v "auto-health-check" | grep -v "maintenance-reminder"; echo "$CRON_ENTRIES") | crontab -

    echo "Cron jobs installed successfully!"
    echo ""
    echo "Current crontab:"
    crontab -l
else
    echo "Skipped cron installation."
    echo ""
    echo "To install manually, run: crontab -e"
    echo "And add the entries shown above."
fi

echo ""
echo "Setup complete!"
echo ""
echo "Quick commands:"
echo "  ./run-ansible.sh health     - Check all nodes"
echo "  ./run-ansible.sh deploy all - Deploy everything"
echo "  ./run-ansible.sh check      - Dry-run (no changes)"
