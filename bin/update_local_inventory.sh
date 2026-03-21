#!/bin/bash
set -euo pipefail

# Writes inventory.ini + SSH config for local QEMU/KVM target VMs (static IPs)

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INVENTORY="$REPO_DIR/inventory.ini"
SSH_CONFIG="$HOME/.ssh/config"
SSH_KEY="$HOME/.ssh/DemoSSHKey"

# Static IPs assigned via cloud-init
SERVER1_IP="192.168.122.101"
SERVER2_IP="192.168.122.102"
SERVER3_IP="192.168.122.103"

# Markers for idempotent SSH config updates
BEGIN_MARKER="# BEGIN cyberforge-demo"
END_MARKER="# END cyberforge-demo"

echo "Local VM IPs (static):"
echo "  target-1: $SERVER1_IP"
echo "  target-2: $SERVER2_IP"
echo "  target-3: $SERVER3_IP"

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
    if grep -q "$BEGIN_MARKER" "$SSH_CONFIG"; then
        sed -i "/$BEGIN_MARKER/,/$END_MARKER/d" "$SSH_CONFIG"
    fi
else
    mkdir -p "$(dirname "$SSH_CONFIG")"
    touch "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
fi

echo "$SSH_BLOCK" >> "$SSH_CONFIG"
echo "Updated $SSH_CONFIG"

echo "Done. Inventory and SSH config are ready for local targets."
