#!/bin/bash
# Sets up the presenter laptop's ~/.ssh/config entry for the ansible control VM.
# Run once on the host (korell), not inside the VM.
set -euo pipefail

SSH_CONFIG="$HOME/.ssh/config"
SSH_KEY="$HOME/.ssh/DemoSSHKey"
CONTROL_IP="192.168.122.100"
BEGIN_MARKER="# BEGIN cyberforge-control"
END_MARKER="# END cyberforge-control"

SSH_BLOCK="$BEGIN_MARKER
Host ansible
    HostName $CONTROL_IP
    User ansible_user
    IdentityFile $SSH_KEY
    AddKeysToAgent yes
    StrictHostKeyChecking accept-new
$END_MARKER"

if [ ! -f "$SSH_CONFIG" ]; then
    mkdir -p "$(dirname "$SSH_CONFIG")"
    touch "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
fi

if grep -q "$BEGIN_MARKER" "$SSH_CONFIG"; then
    sed -i "/$BEGIN_MARKER/,/$END_MARKER/d" "$SSH_CONFIG"
fi

echo "$SSH_BLOCK" >> "$SSH_CONFIG"
echo "Updated $SSH_CONFIG — 'ssh ansible' now connects to $CONTROL_IP"
