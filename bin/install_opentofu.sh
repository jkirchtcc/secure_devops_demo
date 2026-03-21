#!/bin/bash
set -euo pipefail

# Install OpenTofu via the official apt repository on Ubuntu
# Reference: https://opentofu.org/docs/intro/install/deb/

# Install dependencies
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg

# Download the GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://get.opentofu.org/opentofu.gpg | sudo tee /etc/apt/keyrings/opentofu.gpg >/dev/null
sudo chmod a+r /etc/apt/keyrings/opentofu.gpg

# Add the OpenTofu repository
curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey | sudo gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg 2>/dev/null
sudo chmod a+r /etc/apt/keyrings/opentofu-repo.gpg

echo \
  "deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main
deb-src [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" | \
  sudo tee /etc/apt/sources.list.d/opentofu.list > /dev/null

# Install OpenTofu
sudo apt-get update
sudo apt-get install -y tofu

echo "OpenTofu installed successfully."
tofu --version
