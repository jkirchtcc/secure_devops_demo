#!/bin/bash
set -euo pipefail

# Teardown script: destroys OpenTofu infrastructure and cleans up configs

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOFU_DIR="$REPO_DIR/tofu"
INVENTORY="$REPO_DIR/inventory.ini"
SSH_CONFIG="$HOME/.ssh/config"

BEGIN_MARKER="# BEGIN cyberforge-demo"
END_MARKER="# END cyberforge-demo"

# Capture current IPs before destroying
echo "Capturing current droplet IPs..."
IPS_JSON=$(cd "$TOFU_DIR" && tofu output -json droplet_ips 2>/dev/null || echo "{}")
IPS=$(echo "$IPS_JSON" | jq -r 'values[]' 2>/dev/null || true)

# Destroy infrastructure
echo "Destroying OpenTofu infrastructure..."
cd "$TOFU_DIR" && tofu destroy -auto-approve

# Clean known_hosts entries
if [ -n "$IPS" ]; then
    echo "Cleaning SSH known_hosts..."
    for ip in $IPS; do
        ssh-keygen -R "$ip" 2>/dev/null || true
    done
fi

# Reset inventory.ini
cat > "$INVENTORY" <<EOF
[local]
localhost ansible_connection=local

[servers]
EOF
echo "Reset $INVENTORY"

# Remove SSH config entries
if [ -f "$SSH_CONFIG" ] && grep -q "$BEGIN_MARKER" "$SSH_CONFIG"; then
    sed -i "/$BEGIN_MARKER/,/$END_MARKER/d" "$SSH_CONFIG"
    echo "Cleaned $SSH_CONFIG"
fi

echo "Teardown complete."
