#!/bin/bash

# Update the package list
sudo apt update

# Install uv if not already installed
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source $HOME/.local/bin/env
fi

# Install Ansible using uv tool, including its dependencies
uv tool install --with passlib ansible

# Confirm installations
echo "Installed Ansible and passlib using uv."
ansible --version
