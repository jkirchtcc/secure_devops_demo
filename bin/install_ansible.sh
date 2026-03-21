#!/bin/bash

# Update the package list
sudo apt update

# Install uv if not already installed
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source $HOME/.local/bin/env
fi

# Install Ansible using uv tool
# ansible-core provides the CLI tools (ansible, ansible-playbook, etc.)
# ansible provides the collection package, passlib for password hashing
uv tool install --with passlib --with ansible ansible-core

# Confirm installations
echo "Installed Ansible and passlib using uv."
ansible --version
