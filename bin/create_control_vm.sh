#!/bin/bash
set -euo pipefail

# Creates the control VM from an Ubuntu 24.04 cloud image
# Requires: libvirt, virtinst, genisoimage, wget
# Must be run as a user in the libvirt group, or with sudo

VIRSH="sudo virsh --connect qemu:///system"
VM_NAME="ansible"
STATIC_IP="192.168.122.100"
GATEWAY="192.168.122.1"
IMAGE_DIR="$HOME/.cache/cyberforge-demo/images"
VM_DIR="/var/lib/libvirt/images/cyberforge-demo"
IMAGE_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
IMAGE_FILE="noble-server-cloudimg-amd64.img"
SSH_PUBKEY="$HOME/.ssh/DemoSSHKey.pub"

# Check SSH public key exists (used to authorize host -> control-vm access)
if [ ! -f "$SSH_PUBKEY" ]; then
    echo "Error: SSH public key not found at $SSH_PUBKEY"
    echo "Generate one with: ssh-keygen -t ed25519 -C \"DemoSSHKey\" -f ~/.ssh/DemoSSHKey"
    exit 1
fi

SSH_KEY_CONTENT=$(cat "$SSH_PUBKEY")

# Check if VM already exists
if $VIRSH dominfo "$VM_NAME" &>/dev/null; then
    echo "$VM_NAME already exists."
    echo "To recreate, first run:"
    echo "  sudo $VIRSH destroy $VM_NAME; sudo $VIRSH undefine $VM_NAME --remove-all-storage"
    exit 1
fi

mkdir -p "$IMAGE_DIR"
sudo mkdir -p "$VM_DIR"

# Download cloud image if not cached
if [ ! -f "$IMAGE_DIR/$IMAGE_FILE" ]; then
    echo "Downloading Ubuntu 24.04 cloud image..."
    wget -q --show-progress -O "$IMAGE_DIR/$IMAGE_FILE" "$IMAGE_URL"
else
    echo "Using cached $IMAGE_FILE"
fi

VM_DISK="$VM_DIR/${VM_NAME}.qcow2"
SEED_ISO="$VM_DIR/${VM_NAME}-seed.iso"

# Create disk from cloud image
sudo cp "$IMAGE_DIR/$IMAGE_FILE" "$VM_DISK"
sudo qemu-img resize "$VM_DISK" 20G

# Create cloud-init config
CLOUD_INIT_DIR=$(mktemp -d)

cat > "$CLOUD_INIT_DIR/user-data" <<USERDATA
#cloud-config
users:
  - name: ansible_user
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    ssh_pwauth: true
    ssh_authorized_keys:
      - $SSH_KEY_CONTENT
    chpasswd:
      expire: false

ssh_pwauth: true

package_update: true
packages:
  - openssh-server
  - git
  - curl
  - jq
  - gnupg

runcmd:
  - systemctl enable ssh
  - systemctl start ssh
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

# Create the VM with more resources than target VMs
sudo virt-install \
    --connect qemu:///system \
    --name "$VM_NAME" \
    --memory 2048 \
    --vcpus 2 \
    --disk path="$VM_DISK",format=qcow2 \
    --disk path="$SEED_ISO",device=cdrom \
    --os-variant ubuntu24.04 \
    --network network=default \
    --graphics none \
    --console pty,target_type=serial \
    --noautoconsole \
    --import

echo ""
echo "Waiting for $VM_NAME to come up at $STATIC_IP..."
MAX_WAIT=120
ELAPSED=0

echo -n "Waiting..."
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
    echo "Check with: sudo $VIRSH domifaddr $VM_NAME"
    exit 1
fi

echo ""
echo "=== Control VM created ==="
echo "IP: $STATIC_IP"
echo ""
echo "SSH in with:"
echo "  ssh -i ~/.ssh/DemoSSHKey ansible_user@$STATIC_IP"
echo ""
echo "Then inside the VM:"
echo "  git clone https://github.com/jkirchtcc/secure_devops_demo.git"
echo "  cd secure_devops_demo"
echo "  bin/setup_control_vm.sh"
