#!/bin/bash
set -euo pipefail

# Writes SSH config entries for the 3 target VMs using ansible_user.
# Run after add_ansible_user.yml has created ansible_user on the servers.

SSH_CONFIG="$HOME/.ssh/config"
SSH_KEY="$HOME/.ssh/DemoSSHKey"

SERVER1_IP="192.168.122.101"
SERVER2_IP="192.168.122.102"
SERVER3_IP="192.168.122.103"

BEGIN_MARKER="# BEGIN cyberforge-demo"
END_MARKER="# END cyberforge-demo"

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
echo "Updated $SSH_CONFIG — servers now connect as ansible_user"
