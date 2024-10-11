#!/bin/bash

# Update the package list
sudo apt update

# Install pipx if not already installed
sudo apt install -y pipx

# Ensure pipx is on the PATH
pipx ensurepath

# Install Ansible using pipx, including its dependencies
pipx install --include-deps ansible

# Install passlib for Ansible to use password hashing
pipx inject ansible passlib

# Confirm installations
echo "Installed Ansible and passlib using pipx."
ansible --version

