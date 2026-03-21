#!/bin/bash
set -euo pipefail

# Creates 3 local QEMU/KVM target VMs from Ubuntu cloud images
# Requires: libvirt, virtinst, genisoimage, wget

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE_DIR="$HOME/.cache/cyberforge-demo/images"
VM_DIR="$HOME/.local/share/cyberforge-demo/vms"
SSH_PUBKEY="$HOME/.ssh/DemoSSHKey.pub"

# VM definitions: name -> image URL
declare -A VM_IMAGES
VM_IMAGES=(
    ["target-1"]="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    ["target-2"]="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
    ["target-3"]="https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
)

declare -A VM_VARIANTS
VM_VARIANTS=(
    ["target-1"]="ubuntu24.04"
    ["target-2"]="ubuntu22.04"
    ["target-3"]="ubuntu20.04"
)

# Check SSH public key exists
if [ ! -f "$SSH_PUBKEY" ]; then
    echo "Error: SSH public key not found at $SSH_PUBKEY"
    echo "Generate one with: ssh-keygen -t ed25519 -C \"DemoSSHKey\" -f ~/.ssh/DemoSSHKey"
    exit 1
fi

SSH_KEY_CONTENT=$(cat "$SSH_PUBKEY")

mkdir -p "$IMAGE_DIR" "$VM_DIR"

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
    if virsh dominfo "$VM_NAME" &>/dev/null; then
        echo "$VM_NAME already exists, skipping."
        continue
    fi

    URL="${VM_IMAGES[$VM_NAME]}"
    FILENAME=$(basename "$URL")
    VARIANT="${VM_VARIANTS[$VM_NAME]}"
    VM_DISK="$VM_DIR/${VM_NAME}.qcow2"
    SEED_ISO="$VM_DIR/${VM_NAME}-seed.iso"

    # Create a copy of the cloud image as the VM disk
    cp "$IMAGE_DIR/$FILENAME" "$VM_DISK"
    qemu-img resize "$VM_DISK" 10G

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

    # Create seed ISO for cloud-init
    genisoimage -output "$SEED_ISO" -volid cidata -joliet -rock \
        "$CLOUD_INIT_DIR/user-data" "$CLOUD_INIT_DIR/meta-data" 2>/dev/null

    rm -rf "$CLOUD_INIT_DIR"

    # Create the VM
    virt-install \
        --name "$VM_NAME" \
        --memory 512 \
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

# Wait for VMs to get IPs
echo ""
echo "Waiting for VMs to boot and obtain IP addresses..."
MAX_WAIT=120
ELAPSED=0

for VM_NAME in target-1 target-2 target-3; do
    echo -n "Waiting for $VM_NAME..."
    while [ $ELAPSED -lt $MAX_WAIT ]; do
        IP=$(virsh domifaddr "$VM_NAME" 2>/dev/null | grep -oP '192\.168\.\d+\.\d+' | head -1 || true)
        if [ -n "$IP" ]; then
            echo " $IP"
            break
        fi
        sleep 5
        ELAPSED=$((ELAPSED + 5))
        echo -n "."
    done
    if [ -z "$IP" ]; then
        echo " timed out after ${MAX_WAIT}s"
    fi
done

echo ""
echo "Target VMs created. Run 'bin/update_local_inventory.sh' to write the inventory."
