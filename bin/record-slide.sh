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

if [ "$SLIDE" = "7" ]; then
    # Slide 7 shows korell's SSH config (Host ansible entry only).
    # Run demo.sh locally and temporarily show just the ansible control entry
    # so the recording matches the slide (before target servers are added).
    ORIG="$HOME/.ssh/config"
    BACKUP="$HOME/.ssh/config.record-backup-$$"
    cp "$ORIG" "$BACKUP"
    # Write only the cyberforge-control block (Host ansible entry), with User root
    # (slide 7 shows the initial config before switching to ansible_user)
    sed -n '/# BEGIN cyberforge-control/,/# END cyberforge-control/p' "$BACKUP" \
      | sed 's/User ansible_user/User root/' > "$ORIG"
    trap "mv '$BACKUP' '$ORIG'" EXIT
    asciinema rec "$CAST" --command "cd $PWD && bin/demo.sh --slide ${SLIDE}" --overwrite
    mv "$BACKUP" "$ORIG"
    trap - EXIT
else
    asciinema rec "$CAST" --command "ssh ansible 'cd ~/secure_devops_demo && bin/demo.sh --slide ${SLIDE}'" --overwrite
fi

# asciinema doesn't record silent pauses (sleeps produce no PTY output), so
# the cast ends at the last output event.  Inject a synthetic hold event at
# lastEventTime + RECORD_END_PAUSE so the player knows when to loop.
RECORD_END_PAUSE=3
python3 - "$CAST" "$RECORD_END_PAUSE" << 'PYEOF'
import json, sys
cast_file, end_pause = sys.argv[1], float(sys.argv[2])
lines = open(cast_file).read().rstrip('\n').split('\n')
events = [l for l in lines[1:] if l.strip()]
last_time = json.loads(events[-1])[0] if events else 0
hold_event = json.dumps([round(last_time + end_pause, 6), "o", ""])
lines.append(hold_event)
open(cast_file, 'w').write('\n'.join(lines) + '\n')
print(f"  hold event injected at {last_time + end_pause:.2f}s")
PYEOF

echo "Converting to GIF..."
agg "$CAST" "$GIF"

echo "Done: $GIF"
