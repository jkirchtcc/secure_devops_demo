#!/bin/bash
set -euo pipefail

# Tears down the 3 local QEMU/KVM target VMs and cleans up
# Must be run as a user in the libvirt group, or with sudo

VIRSH="sudo virsh --connect qemu:///system"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INVENTORY="$REPO_DIR/inventory.ini"

# Static IPs for known_hosts cleanup
declare -A VM_IPS
VM_IPS=(
    ["target-1"]="192.168.122.101"
    ["target-2"]="192.168.122.102"
    ["target-3"]="192.168.122.103"
)

for VM_NAME in target-1 target-2 target-3; do
    if $VIRSH dominfo "$VM_NAME" &>/dev/null; then
        echo "Destroying $VM_NAME..."

        # Stop the VM if running
        $VIRSH destroy "$VM_NAME" 2>/dev/null || true

        # Remove VM and its storage
        $VIRSH undefine "$VM_NAME" --remove-all-storage 2>/dev/null || true

        # Clean known_hosts
        ssh-keygen -R "${VM_IPS[$VM_NAME]}" 2>/dev/null || true

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
