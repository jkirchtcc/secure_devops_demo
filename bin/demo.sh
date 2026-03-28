#!/bin/bash
# CyberForge 2026 — Interactive Demo Runner
# Run this from ~/secure_devops_demo on the ansible control VM

cd "$(dirname "$0")/.."

# Ensure ~/.local/bin is in PATH (ansible installed via uv)
export PATH="$HOME/.local/bin:$PATH"

# Force Ansible to emit ANSI color even when stdout is not a TTY (e.g. asciinema)
export ANSIBLE_FORCE_COLOR=1

# Flags:
#   --test      run all parts without pausing (for automated testing)
#   --record    run without pausing, with pv typing simulation and custom prompt
#   --slide N   run only slide N (implies --record; for per-slide GIF recording)
# Usage: bin/demo.sh [--test|--record|--slide N] [start_part] [end_part]
TEST_MODE=0
RECORD_MODE=0
SLIDE_FILTER=0
TARGET_SLIDE=""
while true; do
    case "${1:-}" in
        --test)   TEST_MODE=1; shift ;;
        --record) RECORD_MODE=1; TEST_MODE=1; shift ;;
        --slide)  SLIDE_FILTER=1; TARGET_SLIDE="$2"; RECORD_MODE=1; TEST_MODE=1; shift 2 ;;
        *)        break ;;
    esac
done
ARG_START="${1:-}"
ARG_END="${2:-6}"

# ── Colors ────────────────────────────────────────────────────────────────────
BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────

CURRENT_SLIDE=""

header() {
    [ "$SLIDE_FILTER" -eq 1 ] && return
    echo
    echo -e "${CYAN}${BOLD}══════════════════════════════════════════════════════${RESET}"
    echo -e "${CYAN}${BOLD}  $1${RESET}"
    echo -e "${CYAN}${BOLD}══════════════════════════════════════════════════════${RESET}"
    echo
}

slide() {
    CURRENT_SLIDE="$1"
    if [ "$SLIDE_FILTER" -eq 0 ] || [ "$CURRENT_SLIDE" = "$TARGET_SLIDE" ]; then
        echo -e "${YELLOW}▶ Slide $1 — $2${RESET}"
    fi
}

in_slide() {
    [ "$SLIDE_FILTER" -eq 0 ] || [ "$CURRENT_SLIDE" = "$TARGET_SLIDE" ]
}

pause() {
    if [ "$TEST_MODE" -eq 1 ]; then return; fi
    echo
    echo -e "${GREEN}[Press ENTER to continue]${RESET}"
    read -r || true
}

RECORD_PROMPT='ansible:~/secure_devops_demo$ '
RECORD_CMD_PAUSE=1.5   # seconds to pause after each command output
RECORD_END_PAUSE=3     # seconds to hold at end of slide before GIF loops

hold() {
    # Pause at end of a slide recording so output is readable before loop.
    # The printf emits a no-op ANSI sequence AFTER the sleep so asciinema
    # records a terminal event at the hold-end timestamp — without it the
    # player has no event to anchor the end time and loops immediately.
    if [ "$RECORD_MODE" -eq 1 ]; then
        sleep "$RECORD_END_PAUSE"
    fi
}

run() {
    local display=()
    for arg in "$@"; do
        if [[ -z "$arg" ]]; then
            display+=('""')
        elif [[ "$arg" == *" "* ]]; then
            display+=("\"$arg\"")
        else
            display+=("$arg")
        fi
    done
    if [ "$RECORD_MODE" -eq 1 ]; then
        echo -ne "${BOLD}${RECORD_PROMPT}${RESET}"
        printf '%s' "${display[*]}" | pv -qL 8
        echo
        "$@"
        sleep "$RECORD_CMD_PAUSE"
        return
    else
        echo -e "${BOLD}\$ ${display[*]}${RESET}"
    fi
    "$@"
}

before_after() {
    local label="$1"
    local file="$2"
    local cmd="$3"
    echo -e "${BOLD}── BEFORE: $file ──${RESET}"
    cat "$file"
    echo
    pause
    echo -e "${BOLD}\$ $cmd${RESET}"
    eval "$cmd"
    echo
    echo -e "${BOLD}── AFTER: $file ──${RESET}"
    cat "$file"
}

# ── Main ──────────────────────────────────────────────────────────────────────

if [ "$SLIDE_FILTER" -eq 0 ]; then
    echo
    echo -e "${BOLD}CyberForge 2026 — Secure DevOps: Setting up a secure environment for Ansible${RESET}"
    echo -e "Running from: $(pwd)"
    echo -e "Control VM:   $(hostname) ($(hostname -I | awk '{print $1}'))"
    echo
    echo "Parts:"
    echo "  1 - SSH Setup Demo       (slides 4-11)"
    echo "  2 - Ansible Setup Demo   (slides 13-15)"
    echo "  3 - Ansible Demo         (slides 17-19)"
    echo "  4 - Storing Secrets      (slides 21-26)"
    echo "  5 - SSHD Hardening       (slides 28-36)"
    echo "  6 - Ad-hoc Commands      (slide 37)"
    echo
fi

if [ "$SLIDE_FILTER" -eq 1 ]; then
    START_PART=1
    END_PART=6
elif [ "$TEST_MODE" -eq 1 ]; then
    START_PART="${ARG_START:-1}"
elif [ -n "$ARG_START" ]; then
    START_PART="$ARG_START"
else
    echo -e "Enter part number to jump to a specific part, or press ENTER to start from Part 1:"
    read -r START_PART || true
    START_PART=${START_PART:-1}
fi
[ "$SLIDE_FILTER" -eq 0 ] && END_PART="$ARG_END"

# ══════════════════════════════════════════════════════════════════════════════
# PART 1 — SSH Setup Demo
# ══════════════════════════════════════════════════════════════════════════════
if [ "$START_PART" -le 1 ] && [ "$END_PART" -ge 1 ]; then
header "Part 1: SSH Setup Demo  (control VM only — no target VMs yet)"

slide 4 "Generate SSH Keys"
if in_slide; then
    rm -f ~/.ssh/DemoSSHKey ~/.ssh/DemoSSHKey.pub
    run ssh-keygen -t ed25519 -C "DemoSSHKey" -f ~/.ssh/DemoSSHKey -N ""
    pause
    run cat ~/.ssh/DemoSSHKey.pub
    pause
    hold
fi

slide 7 "Configure SSH Client"
if in_slide; then
    run cat ~/.ssh/config
    pause
    hold
fi

fi

# ══════════════════════════════════════════════════════════════════════════════
# PART 2 — Ansible Setup Demo
# ══════════════════════════════════════════════════════════════════════════════
if [ "$START_PART" -le 2 ] && [ "$END_PART" -ge 2 ]; then
header "Part 2: Ansible Setup Demo  (control VM only)"

slide 13 "Ansible Installed"
if in_slide; then
    run ansible --version
    pause
    hold
fi

fi

# ══════════════════════════════════════════════════════════════════════════════
# PART 3 — Ansible Demo
# ══════════════════════════════════════════════════════════════════════════════
if [ "$START_PART" -le 3 ] && [ "$END_PART" -ge 3 ]; then
header "Part 3: Ansible Demo  (control VM only)"

slide 17 "Our First Ansible Playbook"
if in_slide; then
    run cat inventory.ini
    pause
    run cat ping.yml
    pause
    run ansible-playbook -i inventory.ini ping.yml
    pause
    hold
fi

slide 19 "Update ansible with Ansible"
if in_slide; then
    run cat update.yml
    pause
    # Run without vault password so become_password can't be loaded — shows why vault matters
    ANSIBLE_VAULT_PASSWORD_FILE=/nonexistent run ansible-playbook update.yml
    pause
    hold
fi

fi

# ══════════════════════════════════════════════════════════════════════════════
# PART 4 — Storing Secrets
# ══════════════════════════════════════════════════════════════════════════════
if [ "$START_PART" -le 4 ] && [ "$END_PART" -ge 4 ]; then
header "Part 4: Storing Secrets  (control VM only)"

slide 22 "Ansible Vault"
if in_slide; then
    run ansible-vault view vault.yml
    pause
    run cat vault.yml
    pause
    hold
fi

slide 23 "Let's use pass"
if in_slide; then
    run cat bin/get_vault_pass.sh
    pause
    run pass ansible/vault_password
    pause
    hold
fi

slide 25 "ansible.cfg with vault_password_file"
if in_slide; then
    run cat ansible.cfg
    pause
    run cat bin/get_vault_pass.sh
    pause
    hold
fi

fi

# ══════════════════════════════════════════════════════════════════════════════
# PART 5 — SSHD Hardening
# ══════════════════════════════════════════════════════════════════════════════
if [ "$START_PART" -le 5 ] && [ "$END_PART" -ge 5 ]; then
header "Part 5: SSHD Hardening  (adding 3 target VMs now)"

if [ "$SLIDE_FILTER" -eq 0 ]; then
    echo -e "${YELLOW}${BOLD}Target VMs must be in a fresh state for Part 5.${RESET}"
    echo -e "  Run this on korell, then press ENTER:"
    echo -e ""
    echo -e "  ${BOLD}bin/reset_target_vms.sh${RESET}"
    echo -e ""
    pause
fi

slide 28 "Let's spin up more machines"
if in_slide; then
    before_after "inventory.ini" inventory.ini "bin/update_local_inventory.sh"
    pause
    hold
fi

slide 29 "Ansible to update .bashrc"
if in_slide; then
    run cat add_ssh_key.yml
    pause
    run ansible-playbook add_ssh_key.yml
    pause
    hold
fi

slide 30 "Idempotent — run it again"
if in_slide; then
    run ansible-playbook add_ssh_key.yml
    pause
    hold
fi

slide 31 "Now we are ready"
if in_slide; then
    ANSIBLE_HOST_KEY_CHECKING=False run ansible-playbook ping-servers.yml
    pause
    hold
fi

slide 32 "Add ansible_user to servers"
if in_slide; then
    run cat add_ansible_user.yml
    pause
    run ansible-playbook add_ansible_user.yml
    pause
    hold
fi

slide 33 "Switch SSH config to ansible_user"
if in_slide; then
    bin/update_ssh_config.sh > /dev/null
    run cat ~/.ssh/config
    pause
    hold
fi

slide 34 "Verify ansible_user can connect"
if in_slide; then
    run ansible-playbook ping-servers.yml
    pause
    hold
fi

slide 35 "SSHD Hardening"
if in_slide; then
    echo -e "${BOLD}── BEFORE: sshd_config on all servers ──${RESET}"
    run ansible servers -a "grep -E 'PermitRootLogin|PasswordAuthentication|PubkeyAuthentication' /etc/ssh/sshd_config"
    pause
    run cat sshd_hardening-servers.yml
    pause
    run ansible-playbook sshd_hardening-servers.yml
    echo
    echo -e "${BOLD}── AFTER: sshd_config on all servers ──${RESET}"
    run ansible servers -a "grep -E 'PermitRootLogin|PasswordAuthentication|PubkeyAuthentication' /etc/ssh/sshd_config"
    pause
    hold
fi

slide 36 "Verify we can still connect"
if in_slide; then
    run ansible-playbook ping-servers.yml
    pause
    hold
fi

fi

# ══════════════════════════════════════════════════════════════════════════════
# PART 6 — Ad-hoc Commands
# ══════════════════════════════════════════════════════════════════════════════
if [ "$START_PART" -le 6 ] && [ "$END_PART" -ge 6 ]; then
header "Part 6: Ad-hoc Commands"

slide 37 "Ad-hoc commands"
if in_slide; then
    run ansible servers -m setup -a "filter=ansible_distribution*"
    pause
    run ansible servers -m shell -a "df -h"
    pause
    run ansible servers -a "ss -tuln"
    pause
    hold
fi

fi

# ══════════════════════════════════════════════════════════════════════════════
if [ "$SLIDE_FILTER" -eq 0 ]; then
    echo
    echo -e "${GREEN}${BOLD}Demo complete!${RESET}"
    echo
fi
