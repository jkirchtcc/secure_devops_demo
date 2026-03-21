#!/bin/bash
set -euo pipefail

# Reads local QEMU/KVM target VM IPs and writes inventory.ini + SSH config

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INVENTORY="$REPO_DIR/inventory.ini"
SSH_CONFIG="$HOME/.ssh/config"
SSH_KEY="$HOME/.ssh/DemoSSHKey"

# Markers for idempotent SSH config updates
BEGIN_MARKER="# BEGIN cyberforge-demo"
END_MARKER="# END cyberforge-demo"

declare -A VM_IPS

echo "Reading local VM IPs..."
for VM_NAME in target-1 target-2 target-3; do
    if ! virsh dominfo "$VM_NAME" &>/dev/null; then
        echo "Error: $VM_NAME does not exist. Run bin/create_target_vms.sh first."
        exit 1
    fi

    IP=$(virsh domifaddr "$VM_NAME" 2>/dev/null | grep -oP '192\.168\.\d+\.\d+' | head -1 || true)
    if [ -z "$IP" ]; then
        echo "Error: Could not get IP for $VM_NAME. Is it running?"
        exit 1
    fi

    VM_IPS[$VM_NAME]="$IP"
    echo "  $VM_NAME: $IP"
done

SERVER1_IP="${VM_IPS[target-1]}"
SERVER2_IP="${VM_IPS[target-2]}"
SERVER3_IP="${VM_IPS[target-3]}"

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
