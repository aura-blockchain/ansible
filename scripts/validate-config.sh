#!/usr/bin/env bash
# =============================================================================
# AURA CONFIGURATION VALIDATOR
# =============================================================================
# Validates that configuration is consistent across all files.
# Run this before deployments and in CI to catch configuration drift.
#
# Exit codes:
#   0 - All checks passed
#   1 - Validation errors found
#
# Usage:
#   ./scripts/validate-config.sh
#   ./scripts/validate-config.sh --fix  # Attempt auto-fixes (future)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_ROOT="$(dirname "$SCRIPT_DIR")"
AURA_ROOT="${ANSIBLE_ROOT}/../aura"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0

# Canonical values from chain.yml
CANONICAL_CHAIN_ID="aura-mvp-1"
CANONICAL_GO_VERSION="1.23.0"
CANONICAL_DAEMON_NAME="aurad"

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

log_error() {
    echo -e "${RED}ERROR:${NC} $1"
    ((ERRORS++))
}

log_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
    ((WARNINGS++))
}

log_info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

check_file_for_value() {
    local file="$1"
    local pattern="$2"
    local expected="$3"
    local description="$4"

    if [[ -f "$file" ]]; then
        if grep -q "$pattern" "$file" 2>/dev/null; then
            local found
            found=$(grep -oP "$pattern" "$file" 2>/dev/null | head -1)
            if [[ "$found" != "$expected" && -n "$found" ]]; then
                log_error "$description: Expected '$expected' but found '$found' in $file"
                return 1
            fi
        fi
    fi
    return 0
}

# -----------------------------------------------------------------------------
# Validation Checks
# -----------------------------------------------------------------------------

echo "============================================================================="
echo "AURA Configuration Validator"
echo "============================================================================="
echo ""

# Check 1: Verify chain.yml exists and is the source of truth
echo "Checking canonical source of truth..."
if [[ -f "${ANSIBLE_ROOT}/group_vars/chain.yml" ]]; then
    log_success "group_vars/chain.yml exists (canonical source)"
else
    log_error "group_vars/chain.yml not found - create it as the single source of truth"
fi

# Check 2: Chain ID consistency
echo ""
echo "Checking chain_id consistency (expected: ${CANONICAL_CHAIN_ID})..."

# Check ansible files for chain_id duplicates
CHAIN_ID_FILES=(
    "${ANSIBLE_ROOT}/group_vars/all.yml"
    "${ANSIBLE_ROOT}/roles/node/defaults/main.yml"
    "${ANSIBLE_ROOT}/roles/cosmos_exporter/defaults/main.yml"
    "${ANSIBLE_ROOT}/roles/tenderduty/defaults/main.yml"
    "${ANSIBLE_ROOT}/roles/snapshot/defaults/main.yml"
)

for file in "${CHAIN_ID_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        # Check for HARDCODED chain_id (not template references like {{ chain_id }})
        # A hardcoded value is: chain_id: "aura-mvp-1" or chain_id: 'aura-mvp-1'
        # A template reference is: chain_id: "{{ chain_id }}" or chain_id: "{{ chain_id | default(...) }}"
        if grep -E "chain_id.*:.*['\"]aura-" "$file" 2>/dev/null | grep -qv "{{"; then
            log_warning "Hardcoded chain_id definition in $file - should reference chain.yml"
        fi
    fi
done

# Check GitHub workflows
if [[ -d "${AURA_ROOT}/.github/workflows" ]]; then
    for workflow in "${AURA_ROOT}/.github/workflows/"*.yml; do
        if [[ -f "$workflow" ]]; then
            if grep -qE "CHAIN_ID.*:.*aura-mvp-1" "$workflow" 2>/dev/null; then
                log_warning "Hardcoded CHAIN_ID in $(basename "$workflow") - should use ansible vars"
            fi
        fi
    done
fi

# Check 3: Port definitions consistency
echo ""
echo "Checking port definitions..."

# Look for HARDCODED port 9090 (not template references like {{ ports.grpc }})
HARDCODED_PORTS=$(grep -rn "9090" "${ANSIBLE_ROOT}/roles" 2>/dev/null | \
    grep -v ".git" | grep -v "{{" | grep -v "#" | grep -v "default(" || true)
if [[ -n "$HARDCODED_PORTS" ]]; then
    port_count=$(echo "$HARDCODED_PORTS" | wc -l)
    if [[ $port_count -gt 0 ]]; then
        log_warning "Found $port_count hardcoded port 9090 references (should use {{ ports.* }})"
    fi
else
    log_success "No hardcoded port values found in roles"
fi

# Check 4: Variable naming consistency
echo ""
echo "Checking variable naming conventions..."

# Look for inconsistent naming patterns
NAMING_ISSUES=0

# Check for node_chain_id vs chain_id inconsistency
# It's OK if node_chain_id REFERENCES chain_id (e.g., node_chain_id: "{{ chain_id }}")
# It's NOT OK if both are hardcoded with values
if grep -rq "node_chain_id.*['\"]aura-" "${ANSIBLE_ROOT}/group_vars/" 2>/dev/null | grep -qv "{{"; then
    if grep -rq "^chain_id.*['\"]aura-" "${ANSIBLE_ROOT}/group_vars/" 2>/dev/null | grep -qv "{{"; then
        log_warning "Both 'node_chain_id' and 'chain_id' hardcoded in group_vars - one should reference the other"
        ((NAMING_ISSUES++))
    fi
fi

# Check for mixed variable prefixes in roles
for role_dir in "${ANSIBLE_ROOT}/roles/"*/defaults/; do
    if [[ -d "$role_dir" ]]; then
        role_name=$(basename "$(dirname "$role_dir")")
        if [[ -f "${role_dir}/main.yml" ]]; then
            # Check if role uses role-prefixed AND unprefixed vars
            has_prefixed=$(grep -cE "^${role_name}[_-]" "${role_dir}/main.yml" 2>/dev/null || echo "0")
            has_unprefixed=$(grep -cE "^[a-z]+_port:" "${role_dir}/main.yml" 2>/dev/null || echo "0")
            # This is informational, not an error
        fi
    fi
done

# Check 5: Deploy workflow inline inventory
echo ""
echo "Checking GitHub Actions workflows..."

DEPLOY_WORKFLOW="${AURA_ROOT}/.github/workflows/deploy.yml"
if [[ -f "$DEPLOY_WORKFLOW" ]]; then
    if grep -q "Create Ansible inventory" "$DEPLOY_WORKFLOW" 2>/dev/null; then
        log_warning "deploy.yml creates inline inventory - should use aura-ansible repository"
    fi
    if grep -q "Create deployment playbook" "$DEPLOY_WORKFLOW" 2>/dev/null; then
        log_warning "deploy.yml creates inline playbook - should use aura-ansible repository"
    fi
fi

# Check 6: Verify chain-vars.sh is in sync
echo ""
echo "Checking shell script sync..."

CHAIN_VARS_SH="${ANSIBLE_ROOT}/scripts/chain-vars.sh"
if [[ -f "$CHAIN_VARS_SH" ]]; then
    # Check that CHAIN_ID matches
    SH_CHAIN_ID=$(grep -oP 'CHAIN_ID="\K[^"]+' "$CHAIN_VARS_SH" 2>/dev/null || echo "")
    if [[ "$SH_CHAIN_ID" != "$CANONICAL_CHAIN_ID" && -n "$SH_CHAIN_ID" ]]; then
        log_error "chain-vars.sh CHAIN_ID='$SH_CHAIN_ID' doesn't match canonical '$CANONICAL_CHAIN_ID'"
    else
        log_success "chain-vars.sh is in sync with canonical values"
    fi
else
    log_warning "chain-vars.sh not found - scripts cannot source canonical values"
fi

# Check 7: Look for dangerous patterns
echo ""
echo "Checking for dangerous patterns..."

# Check for secrets in variable files
if grep -rE "(password|secret|key|token).*[=:].*['\"][^'\"]{8,}['\"]" \
    "${ANSIBLE_ROOT}/group_vars/" "${ANSIBLE_ROOT}/inventory/" 2>/dev/null | \
    grep -v "vault_" | grep -v "_file:" | head -1 > /dev/null; then
    log_warning "Possible hardcoded secrets found - use vault_ prefix and SOPS"
fi

# Check for localhost/127.0.0.1 in production configs (might be intentional for validators)
LOCALHOST_COUNT=$(grep -rc "127\.0\.0\.1" "${ANSIBLE_ROOT}/inventory/" 2>/dev/null | \
    awk -F: '{sum += $2} END {print sum}')
if [[ ${LOCALHOST_COUNT:-0} -gt 0 ]]; then
    log_info "Found $LOCALHOST_COUNT localhost bindings in inventory (OK for validators)"
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

echo ""
echo "============================================================================="
echo "Validation Summary"
echo "============================================================================="
echo ""

if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
elif [[ $ERRORS -eq 0 ]]; then
    echo -e "${YELLOW}Completed with $WARNINGS warning(s)${NC}"
    echo "Warnings indicate potential issues that should be reviewed."
    exit 0
else
    echo -e "${RED}Completed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "RECOMMENDED ACTIONS:"
    echo "1. Define all chain constants in group_vars/chain.yml"
    echo "2. Remove duplicates from role defaults (reference chain.yml instead)"
    echo "3. Update deploy.yml to clone and use aura-ansible repository"
    echo "4. Use consistent variable naming (prefer unprefixed in chain.yml)"
    exit 1
fi
