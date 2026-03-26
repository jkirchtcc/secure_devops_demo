#!/bin/bash
# Records Part 1 of the CyberForge 2026 demo using asciinema.
# Run from the repo root on korell:
#   asciinema rec docs/recordings/part1.cast --command 'bin/record-part1.sh'
#   agg docs/recordings/part1.cast docs/recordings/part1.gif
#
# Runs automatically — no input needed. Ctrl-C to abort.

ssh ansible 'cd ~/secure_devops_demo && bin/demo.sh --record 1 1'
