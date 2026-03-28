# CyberForge 2026 — Live Demo Script

## Secure DevOps: Setting up a secure environment for Ansible

---

## Pre-Show Checklist (30 minutes before)

- [ ] Laptop charged and plugged in, adapter tested with projector
- [ ] Terminal font >= 16pt, dark theme
- [ ] QEMU/KVM control VM started (`ssh ansible`)
- [ ] Local target VMs in fresh state (`bin/reset_target_vms.sh` on korell)
- [ ] This demo script open in a second terminal
- [ ] Verify `ansible`, `pass`, `gpg` installed in control VM
- [ ] `pass ansible/vault_password` returns the vault password without error

---

## Part 1: SSH Setup Demo

*Control VM (192.168.122.100) only — no target VMs yet*

We need to start by ssh to the Ansible Controller.
ssh 

### Slide 4 - Generate SSH Keys

```bash
# Show the SSH key pair
ls ~/.ssh/DemoSSHKey*

# Show the public key (ED25519 — compare size to RSA 4096)
cat ~/.ssh/DemoSSHKey.pub
```

**Talking points:**
- ED25519 key generation: `ssh-keygen -t ed25519 -C "DemoSSHKey" -f ~/.ssh/DemoSSHKey`
- `-t ed25519` — key type, `-C` — comment, `-f` — filename
- Always use a passphrase on SSH keys

### Slide 5 - Upload SSH Public Key

**Talking points (no live commands):**
- Upload the public key to your servers or cloud provider
- The public key is safe to share — that's the whole point

### Slide 6 - RSA 4096 vs ED25519

**Talking points (no live commands):**
- RSA 4096 key is huge, ED25519 is one line
- Smaller, faster, more secure

### Slide 7 - Configure SSH Client

```bash
# Show the SSH config (no server entries yet — just the control VM)
cat ~/.ssh/config
```

**Talking points:**
- Host alias, HostName (IP), User, IdentityFile
- This is how you avoid typing `ssh -i ~/.ssh/DemoSSHKey ansible_user@192.168.122.101` every time

### Slide 8 - SSH to ansible, part 1

**Talking points (no live commands):**
- First SSH connection prompts for passphrase
- `AddKeysToAgent yes` — enter passphrase once, ssh-agent remembers
- ssh-agent caches the decrypted key in memory

### Slide 9 - CyberSecurity Time

**Talking points (no live commands — covered live in Part 5):**
- Preview of sshd_config hardening: `PermitRootLogin no`, `PubkeyAuthentication yes`, `PasswordAuthentication no`
- We'll do this with Ansible later

### Slide 10 - Update ssh config

**Talking points (no live commands):**
- Change `User root` to `User ansible_user` after creating the user
- Our script handles this automatically

### Slide 11 - SSH Setup Summary

**Talking points (no live commands):**
- Created SSH keys, configured client, connected with keys, hardened SSH
- Question: Are we doing DevOps?

---

## Part 2: Ansible Setup Demo

*Control VM (192.168.122.100) only — no target VMs yet*

### Slide 13 - Install Ansible

```bash
# Show Ansible is installed
ansible --version
```

**Talking points:**
- Installed via `uv tool install ansible-core` with `passlib` injected
- `uv` is a fast Python package manager

### Slide 15 - Ansible Installed

**Talking points (no live commands):**
- Verify the version, Python version, config file location

---

## Part 3: Ansible Demo

*Control VM (192.168.122.100) only — no target VMs yet*

### Slide 17 - Our First Ansible Playbook

```bash
# Show the Ansible config
cat ansible.cfg

# Show the inventory (just [local] — no servers yet)
cat inventory.ini

# Show the ping playbook
cat ping.yml

# Our first playbook — ping localhost
ansible-playbook ping.yml
```

**Talking points:**
- `ansible.cfg` — inventory path, warnings off, vault_password_file
- `ping.yml` targets `hosts: local` — localhost only
- Ansible `ping` is not ICMP — it verifies Ansible can connect and run Python

### Slide 18 - ansible.cfg

**Talking points (no live commands):**
- inventory path, warnings off, interpreter_python
- No need to pass `-i inventory.ini` every time

### Slide 19 - Update ansible with Ansible

```bash
# Show the update playbook — uses become (sudo) and vars_files (vault)
cat update.yml

# Run it — updates packages on localhost
ansible-playbook update.yml
```

**Talking points:**
- `become: yes` uses sudo
- `vars_files: vault.yml` for the become password
- No plaintext passwords anywhere

---

## Part 4: Storing Secrets

*Control VM (192.168.122.100) only — no target VMs yet*

### Slide 21 - Storing Secrets in Ansible

**Talking points (no live commands):**
- Ansible can store secrets in a vault — AES-256 encrypted
- You could use `--ask-vault-pass` but that's not much better than `--ask-become-pass`

### Slide 22 - Ansible Vault

```bash
# Show the encrypted vault file — AES-256 encrypted blob
cat vault.yml

# Show the decrypted vault contents (uses pass automatically via ansible.cfg)
ansible-vault view vault.yml
```

**Talking points:**
- `cat vault.yml` — gibberish, AES-256 encrypted
- `ansible-vault view` decrypts it — shows `ansible_become_password` and `ansible_user_password`

### Slide 23 - Lets use pass

```bash
# Show the script that retrieves the vault password from pass
cat bin/get_vault_pass.sh

# Show pass retrieves the vault password via GPG
pass ansible/vault_password
```

**Talking points:**
- `pass` is the Unix password manager — each secret is a GPG-encrypted file
- `get_vault_pass.sh` just calls `pass ansible/vault_password`

### Slide 24 - pass uses GPG

**Talking points (no live commands):**
- `pass` stores each entry as its own GPG-encrypted file
- GPG agent caches the decryption key, just like ssh-agent caches SSH keys
- Two agents running: ssh-agent for SSH keys, gpg-agent for GPG keys

### Slide 25 - Update ansible.cfg for pass

```bash
# Show ansible.cfg has vault_password_file pointing to get_vault_pass.sh
cat ansible.cfg
```

**Talking points:**
- `vault_password_file = bin/get_vault_pass.sh`
- Chain: `ansible.cfg` -> `get_vault_pass.sh` -> `pass` -> GPG -> vault password -> decrypt `vault.yml`
- No plaintext passwords on disk, ever

### Slide 27 - Okay...

**Talking points (no live commands):**
- "Couldn't I have just run `apt update && apt upgrade -y`?"
- Yes, but that's not DevOps — doesn't scale, error prone, no infrastructure as code

---

## Part 5: SSHD Hardening

*Now we add the 3 target VMs (192.168.122.101-103)*

### Slide 28 - Let's spin up more machines

```bash
# Show the inventory (before — just [local], no servers)
cat inventory.ini

# Show the SSH config (before — no server entries)
cat ~/.ssh/config

# Update inventory and SSH config with local VM IPs
bin/update_local_inventory.sh

# Show the inventory (after — now has [servers] with 3 IPs)
cat inventory.ini

# Show the SSH config (after — now has server1/server2/server3 entries)
cat ~/.ssh/config
```

**Talking points:**
- 3 local VMs: Ubuntu 24.04, 22.04, and 24.10 on QEMU/KVM — no internet needed
- `bin/update_local_inventory.sh` writes both `inventory.ini` and `~/.ssh/config`
- Before/after shows exactly what changed

### Slide 29 - Ansible to update .bashrc

```bash
# Configure ssh-agent auto-start
ansible-playbook add_ssh_key.yml
```

**Talking points:**
- `blockinfile` module adds ssh-agent startup to `.bashrc`
- Now ssh-agent starts automatically on login

### Slide 30 - Idempotent

```bash
# Run it again — notice "ok" instead of "changed"
ansible-playbook add_ssh_key.yml
```

**Talking points:**
- Idempotency: running the same operation twice produces the same result
- First run: `changed=1`, second run: `changed=0`
- Prevents duplication, makes configuration management predictable

### Slide 31 - Now we are ready

```bash
# First connection as root — verify connectivity
ansible servers -m ping -u root
```

**Talking points:**
- First time SSH-ing to these servers, accepting fingerprints
- We connect as root initially because ansible_user doesn't exist yet

### Slide 32 - Add ansible_user to servers

```bash
# Show the add_ansible_user playbook
cat add_ansible_user.yml

# Run it — creates ansible_user, deploys SSH key, sets password from vault
ansible-playbook add_ansible_user.yml
```

**Talking points:**
- `remote_user: root` — connects as root to create the user
- Creates `ansible_user` in sudo group with hashed password from vault
- Deploys SSH public key to `authorized_keys`
- After this, we never need root again

### Slide 34 - Ahhh, I need an ssh client config

```bash
# Show the SSH config has server entries with User ansible_user
cat ~/.ssh/config
```

**Talking points:**
- The SSH config we wrote earlier has `User ansible_user` and `IdentityFile`
- This is why `bin/update_local_inventory.sh` writes both files

### Slide 35 - SSHD Hardening

```bash
# Show current sshd_config on the servers (before)
ansible servers -a "grep -E 'PermitRootLogin|PasswordAuthentication|PubkeyAuthentication' /etc/ssh/sshd_config"

# Show the hardening playbook
cat sshd_hardening-servers.yml

# Run it — disables root login, disables password auth, enables pubkey auth
ansible-playbook sshd_hardening-servers.yml

# Show sshd_config on the servers (after — values changed)
ansible servers -a "grep -E 'PermitRootLogin|PasswordAuthentication|PubkeyAuthentication' /etc/ssh/sshd_config"
```

**Talking points:**
- Three changes across 3 servers in one command: `PermitRootLogin no`, `PubkeyAuthentication yes`, `PasswordAuthentication no`
- Try doing that manually without mistakes
- Before/after grep shows exactly what changed

### Slide 36 - Now we can ping servers

```bash
# Verify everything still works after hardening
ansible-playbook ping-servers.yml
```

**Talking points:**
- We can still connect because we set up SSH keys and ansible_user first
- Root login disabled, password auth disabled — only SSH keys work now

---

## Part 6: Ad-hoc Commands

### Slide 39 - Ad-hoc commands

```bash
# Show OS distribution — 3 different Ubuntu versions, configured identically
ansible servers -m setup -a "filter=ansible_distribution*"

# Disk usage across all servers
ansible servers -m shell -a "df -h"

# Listening ports — only SSH should be open
ansible servers -a "ss -tuln"
```

**Talking points:**
- Ad-hoc commands: run any command across all servers instantly
- `ansible_distribution` shows three different Ubuntu versions, all configured identically with a single set of playbooks
- `ss -tuln` — only SSH (port 22) is listening, minimal attack surface

### Slide 40 - Summary

**Talking points (no live commands):**
- DevOps is awesome
- SSH & GPG keys, SSH-Agent, GPG-Agent, pass, Ansible Vault
- Many demos skip the secure setup — that's what makes this talk different

---

## Post-Demo Teardown

```bash
# Destroy local VMs (on host)
bin/destroy_target_vms.sh
```

