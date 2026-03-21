#!/bin/bash
set -euo pipefail

# Creates 3 local QEMU/KVM target VMs from Ubuntu cloud images with static IPs
# Requires: libvirt, virtinst, genisoimage, wget
# Must be run as a user in the libvirt group, or with sudo

VIRSH="sudo virsh --connect qemu:///system"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE_DIR="$HOME/.cache/cyberforge-demo/images"
VM_DIR="/var/lib/libvirt/images/cyberforge-demo"
SSH_PUBKEY="$HOME/.ssh/DemoSSHKey.pub"
GATEWAY="192.168.122.1"

# VM definitions
declare -A VM_IMAGES VM_VARIANTS VM_IPS
VM_IMAGES=(
    ["target-1"]="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    ["target-2"]="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
    ["target-3"]="https://cloud-images.ubuntu.com/releases/24.10/release/ubuntu-24.10-server-cloudimg-amd64.img"
)
VM_VARIANTS=(
    ["target-1"]="ubuntu24.04"
    ["target-2"]="ubuntu22.04"
    ["target-3"]="ubuntu24.10"
)
VM_IPS=(
    ["target-1"]="192.168.122.101"
    ["target-2"]="192.168.122.102"
    ["target-3"]="192.168.122.103"
)

# Check SSH public key exists
if [ ! -f "$SSH_PUBKEY" ]; then
    echo "Error: SSH public key not found at $SSH_PUBKEY"
    echo "Generate one with: ssh-keygen -t ed25519 -C \"DemoSSHKey\" -f ~/.ssh/DemoSSHKey"
    exit 1
fi

SSH_KEY_CONTENT=$(cat "$SSH_PUBKEY")

mkdir -p "$IMAGE_DIR"
sudo mkdir -p "$VM_DIR"

# Download cloud images if not cached
for VM_NAME in target-1 target-2 target-3; do
    URL="${VM_IMAGES[$VM_NAME]}"
    FILENAME=$(basename "$URL")

    if [ ! -f "$IMAGE_DIR/$FILENAME" ]; then
        echo "Downloading $FILENAME..."
        wget -q --show-progress -O "$IMAGE_DIR/$FILENAME" "$URL"
    else
        echo "Using cached $FILENAME"
    fi
done

# Create and start each VM
for VM_NAME in target-1 target-2 target-3; do
    echo ""
    echo "=== Creating $VM_NAME ==="

    # Check if VM already exists
    if $VIRSH dominfo "$VM_NAME" &>/dev/null; then
        echo "$VM_NAME already exists, skipping."
        continue
    fi

    URL="${VM_IMAGES[$VM_NAME]}"
    FILENAME=$(basename "$URL")
    VARIANT="${VM_VARIANTS[$VM_NAME]}"
    STATIC_IP="${VM_IPS[$VM_NAME]}"
    VM_DISK="$VM_DIR/${VM_NAME}.qcow2"
    SEED_ISO="$VM_DIR/${VM_NAME}-seed.iso"

    # Create a copy of the cloud image as the VM disk
    sudo cp "$IMAGE_DIR/$FILENAME" "$VM_DISK"
    sudo qemu-img resize "$VM_DISK" 10G

    # Create cloud-init config
    CLOUD_INIT_DIR=$(mktemp -d)

    cat > "$CLOUD_INIT_DIR/user-data" <<USERDATA
#cloud-config
users:
  - name: root
    ssh_authorized_keys:
      - $SSH_KEY_CONTENT
ssh_pwauth: false
disable_root: false
USERDATA

    cat > "$CLOUD_INIT_DIR/meta-data" <<METADATA
instance-id: $VM_NAME
local-hostname: $VM_NAME
METADATA

    cat > "$CLOUD_INIT_DIR/network-config" <<NETCONFIG
version: 2
ethernets:
  enp1s0:
    dhcp4: false
    addresses:
      - ${STATIC_IP}/24
    gateway4: ${GATEWAY}
    nameservers:
      addresses:
        - ${GATEWAY}
        - 8.8.8.8
NETCONFIG

    # Create seed ISO for cloud-init (include network-config)
    genisoimage -output "$CLOUD_INIT_DIR/seed.iso" -volid cidata -joliet -rock \
        "$CLOUD_INIT_DIR/user-data" "$CLOUD_INIT_DIR/meta-data" "$CLOUD_INIT_DIR/network-config" 2>/dev/null
    sudo mv "$CLOUD_INIT_DIR/seed.iso" "$SEED_ISO"

    rm -rf "$CLOUD_INIT_DIR"

    # Create the VM
    sudo virt-install \
        --connect qemu:///system \
        --name "$VM_NAME" \
        --memory 1024 \
        --vcpus 1 \
        --disk path="$VM_DISK",format=qcow2 \
        --disk path="$SEED_ISO",device=cdrom \
        --os-variant "$VARIANT" \
        --network network=default \
        --graphics none \
        --console pty,target_type=serial \
        --noautoconsole \
        --import

    echo "$VM_NAME created."
done

# Wait for VMs to come up at their static IPs
echo ""
echo "Waiting for VMs to boot..."
MAX_WAIT=120

for VM_NAME in target-1 target-2 target-3; do
    STATIC_IP="${VM_IPS[$VM_NAME]}"
    ELAPSED=0
    echo -n "Waiting for $VM_NAME ($STATIC_IP)..."
    while [ $ELAPSED -lt $MAX_WAIT ]; do
        if ping -c 1 -W 1 "$STATIC_IP" &>/dev/null; then
            echo " up!"
            break
        fi
        sleep 5
        ELAPSED=$((ELAPSED + 5))
        echo -n "."
    done
    if [ $ELAPSED -ge $MAX_WAIT ]; then
        echo " timed out after ${MAX_WAIT}s"
    fi
done

echo ""
echo "Target VMs created."
echo "  target-1: 192.168.122.101 (Ubuntu 24.04)"
echo "  target-2: 192.168.122.102 (Ubuntu 22.04)"
echo "  target-3: 192.168.122.103 (Ubuntu 24.10)"
echo ""
echo "Run 'bin/update_local_inventory.sh' to write the inventory."
