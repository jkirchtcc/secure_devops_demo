#!/bin/bash
set -euo pipefail

# Destroys and recreates the 3 local QEMU/KVM target VMs in one step.
# Run on the host (korell), not inside the control VM.

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Resetting target VMs to fresh state..."
"$REPO_DIR/bin/destroy_target_vms.sh"
"$REPO_DIR/bin/create_target_vms.sh"
echo "Target VMs reset complete."
