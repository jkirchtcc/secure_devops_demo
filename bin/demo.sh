#!/bin/bash
# CyberForge 2026 — Interactive Demo Runner
# Run this from ~/secure_devops_demo on the ansible control VM

cd "$(dirname "$0")/.."

# Ensure ~/.local/bin is in PATH (ansible installed via uv)
export PATH="$HOME/.local/bin:$PATH"

# --test flag: run all parts without pausing (for automated testing)
TEST_MODE=0
if [ "${1:-}" = "--test" ]; then
    TEST_MODE=1
fi

# ── Colors ────────────────────────────────────────────────────────────────────
BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────

header() {
    echo
    echo -e "${CYAN}${BOLD}══════════════════════════════════════════════════════${RESET}"
    echo -e "${CYAN}${BOLD}  $1${RESET}"
    echo -e "${CYAN}${BOLD}══════════════════════════════════════════════════════${RESET}"
    echo
}

slide() {
    echo -e "${YELLOW}▶ Slide $1 — $2${RESET}"
}

pause() {
    if [ "$TEST_MODE" -eq 1 ]; then return; fi
    echo
    echo -e "${GREEN}[Press ENTER to continue]${RESET}"
    read -r || true
}

run() {
    echo -e "${BOLD}\$ $*${RESET}"
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
if [ "$TEST_MODE" -eq 1 ]; then
    START_PART=1
else
    echo -e "Enter part number to jump to a specific part, or press ENTER to start from Part 1:"
    read -r START_PART || true
    START_PART=${START_PART:-1}
fi

# ══════════════════════════════════════════════════════════════════════════════
# PART 1 — SSH Setup Demo
# ══════════════════════════════════════════════════════════════════════════════
if [ "$START_PART" -le 1 ]; then
header "Part 1: SSH Setup Demo  (control VM only — no target VMs yet)"

slide 4 "Generate SSH Keys"
run ls ~/.ssh/DemoSSHKey*
pause
run cat ~/.ssh/DemoSSHKey.pub
pause

slide 7 "Configure SSH Client"
run cat ~/.ssh/config
pause

fi

# ══════════════════════════════════════════════════════════════════════════════
# PART 2 — Ansible Setup Demo
# ══════════════════════════════════════════════════════════════════════════════
if [ "$START_PART" -le 2 ]; then
header "Part 2: Ansible Setup Demo  (control VM only)"

slide 13 "Ansible Installed"
run ansible --version
pause

fi

# ══════════════════════════════════════════════════════════════════════════════
# PART 3 — Ansible Demo
# ══════════════════════════════════════════════════════════════════════════════
if [ "$START_PART" -le 3 ]; then
header "Part 3: Ansible Demo  (control VM only)"

slide 17 "Our First Ansible Playbook"
run cat ansible.cfg
pause
run cat inventory.ini
pause
run cat ping.yml
pause
run ansible-playbook ping.yml
pause

slide 19 "Update ansible with Ansible"
run cat update.yml
pause
run ansible-playbook update.yml
pause

fi

# ══════════════════════════════════════════════════════════════════════════════
# PART 4 — Storing Secrets
# ══════════════════════════════════════════════════════════════════════════════
if [ "$START_PART" -le 4 ]; then
header "Part 4: Storing Secrets  (control VM only)"

slide 22 "Ansible Vault"
run cat vault.yml
pause
run ansible-vault view vault.yml
pause

slide 23 "Let's use pass"
run cat bin/get_vault_pass.sh
pause
run pass ansible/vault_password
pause

slide 25 "ansible.cfg with vault_password_file"
run cat ansible.cfg
pause

fi

# ══════════════════════════════════════════════════════════════════════════════
# PART 5 — SSHD Hardening
# ══════════════════════════════════════════════════════════════════════════════
if [ "$START_PART" -le 5 ]; then
header "Part 5: SSHD Hardening  (adding 3 target VMs now)"

echo -e "${YELLOW}${BOLD}Target VMs must be in a fresh state for Part 5.${RESET}"
echo -e "  Run this on korell, then press ENTER:"
echo -e ""
echo -e "  ${BOLD}bin/reset_target_vms.sh${RESET}"
echo -e ""
pause

slide 28 "Let's spin up more machines"
before_after "inventory.ini" inventory.ini "bin/update_local_inventory.sh"
pause
echo -e "${BOLD}── AFTER: ~/.ssh/config ──${RESET}"
cat ~/.ssh/config
pause

slide 29 "Ansible to update .bashrc"
run ansible-playbook add_ssh_key.yml
pause

slide 30 "Idempotent — run it again"
run ansible-playbook add_ssh_key.yml
pause

slide 31 "First connection to servers as root"
run ansible servers -m ping -u root
pause

slide 32 "Add ansible_user to servers"
run cat add_ansible_user.yml
pause
run ansible-playbook add_ansible_user.yml
pause

slide 34 "SSH client config has server entries"
run cat ~/.ssh/config
pause

slide 35 "SSHD Hardening"
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

slide 36 "Verify we can still connect"
run ansible-playbook ping-servers.yml
pause

fi

# ══════════════════════════════════════════════════════════════════════════════
# PART 6 — Ad-hoc Commands
# ══════════════════════════════════════════════════════════════════════════════
if [ "$START_PART" -le 6 ]; then
header "Part 6: Ad-hoc Commands"

slide 37 "Ad-hoc commands"
run ansible servers -m setup -a "filter=ansible_distribution*"
pause
run ansible servers -m shell -a "df -h"
pause
run ansible servers -a "ss -tuln"
pause

fi

# ══════════════════════════════════════════════════════════════════════════════
echo
echo -e "${GREEN}${BOLD}Demo complete!${RESET}"
echo
