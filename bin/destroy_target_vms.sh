#!/bin/bash
set -euo pipefail

# Tears down the 3 local QEMU/KVM target VMs and cleans up

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INVENTORY="$REPO_DIR/inventory.ini"

for VM_NAME in target-1 target-2 target-3; do
    if virsh dominfo "$VM_NAME" &>/dev/null; then
        echo "Destroying $VM_NAME..."

        # Get IP before destroying (for known_hosts cleanup)
        IP=$(virsh domifaddr "$VM_NAME" 2>/dev/null | grep -oP '192\.168\.\d+\.\d+' | head -1 || true)

        # Stop the VM if running
        virsh destroy "$VM_NAME" 2>/dev/null || true

        # Remove VM and its storage
        virsh undefine "$VM_NAME" --remove-all-storage 2>/dev/null || true

        # Clean known_hosts
        if [ -n "$IP" ]; then
            ssh-keygen -R "$IP" 2>/dev/null || true
        fi

        echo "$VM_NAME destroyed."
    else
        echo "$VM_NAME does not exist, skipping."
    fi
done

# Reset inventory.ini
cat > "$INVENTORY" <<EOF
[local]
localhost ansible_connection=local

[servers]
EOF
echo "Reset $INVENTORY"

echo "Local VM teardown complete."
