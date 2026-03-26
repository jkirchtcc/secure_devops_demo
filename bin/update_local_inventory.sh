#!/bin/bash
set -euo pipefail

# Writes inventory.ini for local QEMU/KVM target VMs (static IPs)
# Run this first to add targets. Run update_ssh_config.sh after creating ansible_user.

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INVENTORY="$REPO_DIR/inventory.ini"

# Static IPs assigned via cloud-init
SERVER1_IP="192.168.122.101"
SERVER2_IP="192.168.122.102"
SERVER3_IP="192.168.122.103"

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

# Clear stale known_hosts entries for target IPs (new VMs have new host keys)
for IP in "$SERVER1_IP" "$SERVER2_IP" "$SERVER3_IP"; do
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$IP" 2>/dev/null || true
done
echo "Cleared stale known_hosts entries for target IPs"

echo "Done. Run bin/update_ssh_config.sh after creating ansible_user."
