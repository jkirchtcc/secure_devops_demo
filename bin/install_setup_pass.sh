#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Check if pass is installed; if not, install it.
if ! command -v pass &> /dev/null; then
    echo "Installing pass, the Unix password manager..."
    sudo apt update
    sudo apt install -y pass
else
    echo "Pass is already installed."
fi

# Generate a GPG key if it does not exist.
if ! gpg --list-keys | grep -q "ansible_user"; then
    echo "Generating a new GPG key for pass..."
    gpg --batch --generate-key <<EOF
Key-Type: RSA
Key-Length: 2048
Subkey-Type: RSA
Subkey-Length: 2048
Name-Real: Ansible User
Name-Email: ansible@example.com
Expire-Date: 0
%no-protection
EOF
else
    echo "GPG key already exists."
fi

# Get the GPG key ID for pass initialization.
KEY_ID=$(gpg --list-keys --with-colons | grep pub | cut -d ':' -f 5 | head -n 1)

# Initialize pass with the GPG key if not already initialized.
if ! pass grep -q "^Password Store" &> /dev/null; then
    echo "Initializing pass with GPG key ID: $KEY_ID"
    pass init "$KEY_ID"
else
    echo "Pass is already initialized with GPG key ID: $KEY_ID"
fi

# Store the Ansible Vault password securely in pass.
echo -n "Enter the password for the Ansible Vault: "
read -s VAULT_PASSWORD
echo
echo "$VAULT_PASSWORD" | pass insert -m ansible/vault_password

echo "Ansible Vault password has been securely stored in pass under 'ansible/vault_password'."

