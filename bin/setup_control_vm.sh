#!/bin/bash
set -euo pipefail

# One-script setup for the control VM after first boot
# Run this after cloning the repo inside the control VM

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Control VM Setup ==="
echo ""

# Install prerequisites
echo "--- Installing prerequisites ---"
sudo apt-get update
sudo apt-get install -y jq gnupg openssh-client git curl

# Install OpenTofu
echo ""
echo "--- Installing OpenTofu ---"
"$REPO_DIR/bin/install_opentofu.sh"

# Install Ansible
echo ""
echo "--- Installing Ansible ---"
"$REPO_DIR/bin/install_ansible.sh"

# Set up pass + GPG (interactive — prompts for vault password)
echo ""
echo "--- Setting up pass + GPG ---"
"$REPO_DIR/bin/install_setup_pass.sh"

# SSH key generation
echo ""
echo "--- SSH Key Setup ---"
if [ ! -f "$HOME/.ssh/DemoSSHKey" ]; then
    echo "Generating SSH key pair..."
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "DemoSSHKey" -f "$HOME/.ssh/DemoSSHKey"
    echo "SSH key generated at ~/.ssh/DemoSSHKey"
else
    echo "SSH key already exists at ~/.ssh/DemoSSHKey"
fi

# DO token setup
echo ""
echo "--- DigitalOcean API Token ---"
if pass digitalocean/api_token &>/dev/null; then
    echo "DO token already stored in pass."
else
    echo "Store your DigitalOcean API token in pass:"
    echo "  pass insert digitalocean/api_token"
    echo "(You can do this later if you only need local targets.)"
fi

echo ""
echo "=== Control VM setup complete ==="
echo ""
echo "Next steps:"
echo "  1. Copy ~/.ssh/DemoSSHKey.pub to the host for local target VMs"
echo "  2. Run 'bin/create_target_vms.sh' on the host to create local targets"
echo "  3. Run 'bin/update_local_inventory.sh' to populate the inventory"
echo "  4. Run 'ansible-playbook add_ansible_user.yml' to configure targets"
