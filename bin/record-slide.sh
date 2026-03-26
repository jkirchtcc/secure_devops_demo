#!/bin/bash
# Records a single slide's demo commands as an asciinema cast + GIF.
# Run from the repo root on korell.
#
# Usage:
#   bin/record-slide.sh <slide_number>
#
# Output:
#   docs/recordings/slide-<N>.cast
#   docs/recordings/slide-<N>.gif
#
# Note: slides 28-36 require target VMs to be running (bin/reset_target_vms.sh).

set -euo pipefail

SLIDE="${1:-}"
if [ -z "$SLIDE" ]; then
    echo "Usage: $0 <slide_number>" >&2
    exit 1
fi

CAST="docs/recordings/slide-${SLIDE}.cast"
GIF="docs/recordings/slide-${SLIDE}.gif"

mkdir -p docs/recordings

echo "Recording slide ${SLIDE}..."
asciinema rec "$CAST" --command "ssh ansible 'cd ~/secure_devops_demo && bin/demo.sh --slide ${SLIDE}'" --overwrite

echo "Converting to GIF..."
agg "$CAST" "$GIF"

echo "Done: $GIF"
