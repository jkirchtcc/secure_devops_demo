#!/bin/bash
# Wrapper for t-rec: records Part 1 of the CyberForge 2026 demo
# Run from the repo root on korell:
#   t-rec -o docs/recordings/part1 bin/record-part1.sh
#
# Runs automatically — no input needed. Ctrl-C to abort.

ssh ansible 'cd ~/secure_devops_demo && bin/demo.sh 1 1'
