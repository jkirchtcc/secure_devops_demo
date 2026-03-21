#!/bin/bash
set -euo pipefail

# Reads OpenTofu output and updates Ansible inventory + SSH config for DO droplets
# Requires: jq, tofu

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOFU_DIR="$REPO_DIR/tofu"
INVENTORY="$REPO_DIR/inventory.ini"
SSH_CONFIG="$HOME/.ssh/config"
SSH_KEY="$HOME/.ssh/DemoSSHKey"

# Markers for idempotent SSH config updates
BEGIN_MARKER="# BEGIN cyberforge-demo"
END_MARKER="# END cyberforge-demo"

# Get droplet IPs from OpenTofu output
echo "Reading OpenTofu output..."
IPS_JSON=$(cd "$TOFU_DIR" && tofu output -json droplet_ips)

if [ -z "$IPS_JSON" ] || [ "$IPS_JSON" = "{}" ]; then
    echo "Error: No droplet IPs found in OpenTofu output."
    exit 1
fi

# Parse IPs
SERVER1_IP=$(echo "$IPS_JSON" | jq -r '.server1')
SERVER2_IP=$(echo "$IPS_JSON" | jq -r '.server2')
SERVER3_IP=$(echo "$IPS_JSON" | jq -r '.server3')

echo "Found IPs:"
echo "  server1: $SERVER1_IP"
echo "  server2: $SERVER2_IP"
echo "  server3: $SERVER3_IP"

# Write inventory.ini
cat > "$INVENTORY" <<EOF
[local]
localhost ansible_connection=local

[servers]
$SERVER1_IP
$SERVER2_IP
$SERVER3_IP
EOF
echo "Updated $INVENTORY"

# Build SSH config block
SSH_BLOCK="$BEGIN_MARKER
Host server1
    HostName $SERVER1_IP
    User ansible_user
    IdentityFile $SSH_KEY
    AddKeysToAgent yes
    StrictHostKeyChecking accept-new

Host server2
    HostName $SERVER2_IP
    User ansible_user
    IdentityFile $SSH_KEY
    AddKeysToAgent yes
    StrictHostKeyChecking accept-new

Host server3
    HostName $SERVER3_IP
    User ansible_user
    IdentityFile $SSH_KEY
    AddKeysToAgent yes
    StrictHostKeyChecking accept-new
$END_MARKER"

# Update SSH config idempotently
if [ -f "$SSH_CONFIG" ]; then
    # Remove existing block if present
    if grep -q "$BEGIN_MARKER" "$SSH_CONFIG"; then
        sed -i "/$BEGIN_MARKER/,/$END_MARKER/d" "$SSH_CONFIG"
    fi
else
    mkdir -p "$(dirname "$SSH_CONFIG")"
    touch "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
fi

# Append new block
echo "$SSH_BLOCK" >> "$SSH_CONFIG"
echo "Updated $SSH_CONFIG"

echo "Done. Inventory and SSH config are ready."
