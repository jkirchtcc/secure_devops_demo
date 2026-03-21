# CyberForge 2026 — Live Demo Script

## Secure DevOps: Setting up a secure environment for Ansible

---

## Pre-Show Checklist (30 minutes before)

- [ ] Laptop charged and plugged in, adapter tested with projector
- [ ] Terminal font >= 16pt, dark theme
- [ ] QEMU/KVM control VM started
- [ ] Local target VMs created (`bin/create_target_vms.sh`) and running
- [ ] Internet connectivity verified (for Phase 2)
- [ ] `export TF_VAR_do_token=$(pass digitalocean/api_token)` run in control VM
- [ ] DigitalOcean console open in browser (fallback for Phase 2)
- [ ] This demo script open in a second terminal
- [ ] Verify `ansible`, `tofu`, `pass`, `gpg`, `jq` installed in control VM
- [ ] Previous demo infrastructure torn down (local: `bin/destroy_target_vms.sh`, cloud: `bin/teardown.sh`)

---

## Part 1: SSH & GPG Setup (Talking Points — No Live Commands)

**Key points to cover:**

- Why we use SSH keys instead of passwords
- ED25519 key generation: `ssh-keygen -t ed25519 -C "DemoSSHKey" -f ~/.ssh/DemoSSHKey`
- Always use a passphrase on SSH keys
- GPG key for encrypting secrets at rest
- `pass` — the Unix password manager backed by GPG
- Ansible Vault password stored in `pass`, retrieved via `bin/get_vault_pass.sh`

**Architecture slide talking points:**
- Everything runs from one control VM — Ansible, OpenTofu, pass, GPG, SSH keys
- Phase 1: local QEMU/KVM targets (no internet needed)
- Phase 2: same playbooks target cloud servers provisioned by OpenTofu
- The playbooks don't care where the servers are — just IPs in an inventory file

---

## Part 2: Local Demo — Ansible Against QEMU/KVM Targets

### Show the local target VMs

```bash
# Show the 3 local VMs running
virsh list --all

# Show their IPs
bin/update_local_inventory.sh

# Show the inventory
cat inventory.ini
```

**Talking point:** "We have 3 local VMs — Ubuntu 24.04, 22.04, and 20.04 — running on QEMU/KVM. No internet needed, no cloud costs. Perfect for development and testing."

### Verify connectivity

```bash
# First connection as root
ansible servers -m ping -u root
```

### Add the SSH key to the agent

```bash
ansible-playbook add_ssh_key.yml
```

### Run the update playbook

```bash
ansible-playbook update.yml
```

### Add ansible_user to all servers

```bash
ansible-playbook add_ansible_user.yml
```

**Talking point:** "This playbook connects as root, creates `ansible_user` with a hashed password from Ansible Vault, and deploys our SSH public key. After this, we never need root again."

### Harden SSH on all servers

```bash
ansible-playbook sshd_hardening-servers.yml
```

**Talking point:** "We just disabled root login and password authentication across 3 servers in one command. Try doing that manually without mistakes."

### Verify everything works

```bash
# Ping all servers as ansible_user
ansible-playbook ping-servers.yml

# Ad-hoc commands
ansible servers -m setup -a "filter=ansible_distribution*"
ansible servers -m shell -a "df -h"
ansible servers -a "ss -tuln"
```

**Talking point on `ansible_distribution`:** "Three different Ubuntu versions, all configured identically with a single set of playbooks."

---

## Part 3: Cloud Demo — OpenTofu + Ansible Against DO Droplets

**Talking point:** "Now let's do the same thing, but in the cloud. Same playbooks, different targets."

### Show the OpenTofu code

```bash
cat tofu/main.tf
cat tofu/variables.tf
cat tofu/outputs.tf
```

**Talking point:** "We're provisioning 3 Ubuntu droplets — 24.04, 22.04, and 20.04 — to show Ansible working across different OS versions. The exact same versions as our local VMs."

**Talking point:** "Notice `sensitive = true` on the token variable — OpenTofu won't show this in plan or apply output."

### Provision the infrastructure

```bash
export TF_VAR_do_token=$(pass digitalocean/api_token)

cd tofu
tofu init
tofu plan
```

**Talking point during plan:** "The plan shows exactly what will be created before we commit. Infrastructure as code means we can review, version, and audit every change."

```bash
tofu apply
```

**While waiting (~60-90s):** Talk about IaC benefits:
- Reproducible environments
- Version-controlled infrastructure
- Peer review via pull requests
- Easy teardown — no orphaned resources

### Update inventory with cloud IPs

```bash
cd ..
bin/update_inventory.sh
cat inventory.ini
```

**Talking point:** "This script reads the IPs from OpenTofu output and writes them into our Ansible inventory and SSH config. Same inventory format as the local VMs."

### Run the same playbooks against cloud targets

```bash
ansible-playbook add_ansible_user.yml
ansible-playbook sshd_hardening-servers.yml
ansible-playbook ping-servers.yml
ansible servers -m setup -a "filter=ansible_distribution*"
```

**Talking point:** "The exact same playbooks that just configured our local VMs are now configuring 3 cloud servers. The only thing that changed was the inventory."

---

## Post-Demo Teardown

```bash
# Destroy cloud infrastructure
bin/teardown.sh

# Destroy local VMs (on host)
bin/destroy_target_vms.sh
```

**Talking point:** "One command tears down everything — destroys the droplets, cleans SSH known hosts, resets the inventory. No orphaned resources, no lingering SSH keys in known_hosts."

---

## Fallback Plan

If WiFi fails during the live demo:
1. Skip Part 3 (cloud demo)
2. Phase 1 (local VMs) is already a complete demo
3. Show the OpenTofu code and explain what it would do
4. "The same playbooks you just saw work against local VMs would configure cloud servers — the only difference is the inventory file"
