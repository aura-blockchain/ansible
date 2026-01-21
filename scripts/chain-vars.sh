#!/usr/bin/env bash
# =============================================================================
# AURA CHAIN VARIABLES - SHELL SCRIPT VERSION
# =============================================================================
# This file mirrors group_vars/chain.yml for shell scripts.
# Source this file instead of hardcoding values.
#
# Usage:
#   source /path/to/aura-ansible/scripts/chain-vars.sh
#   echo "Chain ID: $CHAIN_ID"
#
# IMPORTANT: Keep this file in sync with group_vars/chain.yml
# Run scripts/validate-config.sh to verify consistency.
# =============================================================================

# -----------------------------------------------------------------------------
# Chain Identity
# -----------------------------------------------------------------------------
export CHAIN_ID="aura-mvp-1"
export CHAIN_NAME="AURA"
export CHAIN_BECH32_PREFIX="aura"
export CHAIN_STAKING_DENOM="uaura"
export CHAIN_DENOM_COEFFICIENT="1000000"
export CHAIN_MINIMUM_GAS_PRICES="0.025uaura"

# -----------------------------------------------------------------------------
# Daemon Configuration
# -----------------------------------------------------------------------------
export DAEMON_NAME="aurad"
export DAEMON_USER="ubuntu"

# -----------------------------------------------------------------------------
# Version Pinning
# -----------------------------------------------------------------------------
export GO_VERSION="1.23.0"
export COSMOVISOR_VERSION="v1.5.0"
export NODE_EXPORTER_VERSION="1.7.0"
export PROMETHEUS_VERSION="2.48.0"

# -----------------------------------------------------------------------------
# Artifact URLs
# -----------------------------------------------------------------------------
export GENESIS_URL="https://artifacts.aurablockchain.org/${CHAIN_ID}/genesis.json"
export PEERS_URL="https://artifacts.aurablockchain.org/${CHAIN_ID}/peers.txt"

# -----------------------------------------------------------------------------
# Standard Ports (defaults - override per environment)
# -----------------------------------------------------------------------------
export PORT_RPC="${PORT_RPC:-26657}"
export PORT_P2P="${PORT_P2P:-26656}"
export PORT_GRPC="${PORT_GRPC:-9090}"
export PORT_API="${PORT_API:-1317}"
export PORT_PROMETHEUS="${PORT_PROMETHEUS:-26660}"

# -----------------------------------------------------------------------------
# VPN Configuration
# -----------------------------------------------------------------------------
export VPN_NETWORK="10.10.0.0/24"

# -----------------------------------------------------------------------------
# Helper function to validate required variables are set
# -----------------------------------------------------------------------------
validate_chain_vars() {
    local required_vars=(
        "CHAIN_ID"
        "DAEMON_NAME"
        "GO_VERSION"
    )

    local missing=()
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing+=("$var")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "ERROR: Missing required chain variables: ${missing[*]}" >&2
        return 1
    fi

    return 0
}
