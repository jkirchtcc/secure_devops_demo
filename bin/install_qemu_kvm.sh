#!/bin/bash
set -euo pipefail

# Installs QEMU/KVM, libvirt, virt-manager, and related tools on Ubuntu host

echo "Installing QEMU/KVM and related packages..."
sudo apt-get update
sudo apt-get install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    virt-manager \
    virtinst \
    genisoimage \
    bridge-utils

# Add current user to libvirt and kvm groups
CURRENT_USER=$(whoami)
sudo usermod -aG libvirt "$CURRENT_USER"
sudo usermod -aG kvm "$CURRENT_USER"

# Enable and start libvirtd
sudo systemctl enable libvirtd
sudo systemctl start libvirtd

echo ""
echo "QEMU/KVM installed successfully."
echo "User '$CURRENT_USER' added to libvirt and kvm groups."
echo ""
echo "IMPORTANT: Log out and back in for group membership to take effect."
echo ""

# Verify
virsh --version
echo "libvirt version: $(virsh --version)"
kvm-ok 2>/dev/null || echo "Note: kvm-ok not available, check /dev/kvm manually"
ls -la /dev/kvm 2>/dev/null || echo "Warning: /dev/kvm not found — check BIOS virtualization settings"
