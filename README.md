# Secure DevOps: Setting up a secure environment for Ansible

Demo project for CyberForge 2026 — demonstrating a full end-to-end IaC pipeline: **OpenTofu provisions infrastructure, Ansible configures it**.

## Architecture

Everything runs from a single QEMU/KVM control VM. The demo has two phases:

```
Phase 1: Local (no internet needed)
──────────────────────────────────────
korell (presenter laptop)
  └── QEMU/KVM
      ├── Control VM (Ubuntu 24.04)
      │     All tools: Ansible, OpenTofu, pass, GPG, SSH keys
      │     Runs Ansible against target VMs
      │
      ├── target-1 (Ubuntu 24.04)
      ├── target-2 (Ubuntu 22.04)
      └── target-3 (Ubuntu 24.10)
      All on virbr0 (192.168.122.0/24)

Phase 2: Cloud (extends Phase 1, needs internet)
──────────────────────────────────────
Same Control VM
  ├── OpenTofu provisions 3 DO droplets
  └── Ansible configures them
      Same playbooks, different inventory
```

**Phase 1** works offline as a standalone demo. **Phase 2** extends it with cloud provisioning. If WiFi fails at the venue, Phase 1 alone is a complete presentation.

## Prerequisites

- **QEMU/KVM** — installed on the host machine (`bin/install_qemu_kvm.sh`)
- **Control VM** — created with `bin/create_control_vm.sh`, set up with `bin/setup_control_vm.sh`
- **SSH Key** — `DemoSSHKey` and `DemoSSHKey.pub` in `~/.ssh/`
- **pass + GPG** — vault password stored in `pass`
- **DigitalOcean API token** — stored in `pass` (Phase 2 only)

## Files Overview

### Setup Scripts
- **`bin/install_qemu_kvm.sh`** — Installs QEMU/KVM + virt-manager on the host
- **`bin/create_control_vm.sh`** — Creates the control VM from Ubuntu 24.04 cloud image
- **`bin/setup_control_vm.sh`** — One-script control VM setup (Ansible, OpenTofu, pass, GPG)
- **`bin/install_ansible.sh`** — Installs Ansible via uv
- **`bin/install_opentofu.sh`** — Installs OpenTofu via official apt repository
- **`bin/install_setup_pass.sh`** — Sets up pass + GPG for vault password storage

### Phase 1: Local VM Scripts (run on host)
- **`bin/create_target_vms.sh`** — Creates 3 local QEMU/KVM target VMs from cloud images
- **`bin/destroy_target_vms.sh`** — Tears down local target VMs and cleans up
- **`bin/update_local_inventory.sh`** — Reads local VM IPs, writes `inventory.ini`

### Phase 2: Cloud Scripts (run from control VM)
- **`bin/update_inventory.sh`** — Reads OpenTofu output, writes `inventory.ini` and `~/.ssh/config`
- **`bin/teardown.sh`** — Destroys DO infrastructure, cleans SSH configs and known_hosts

### OpenTofu (Phase 2)
- **`tofu/providers.tf`** — DigitalOcean provider configuration
- **`tofu/variables.tf`** — Input variables (token, region, size, SSH key path)
- **`tofu/main.tf`** — Droplet and SSH key resources (3 Ubuntu versions)
- **`tofu/outputs.tf`** — Droplet IP address map
- **`tofu/terraform.tfvars.example`** — Template for variable values

### Ansible Playbooks (run from control VM)
- **`ansible.cfg`** — Ansible settings (inventory, vault password file)
- **`add_ansible_user.yml`** — Creates `ansible_user` with SSH key and hashed password
- **`add_ssh_key.yml`** — Configures ssh-agent to load DemoSSHKey
- **`ping-servers.yml`** — Verifies connectivity to servers
- **`ping.yml`** — Pings localhost to confirm local Ansible setup
- **`sshd_hardening-servers.yml`** — Hardens SSH (disables root login, password auth)
- **`update.yml`** — Updates and upgrades packages on localhost

### Utility
- **`bin/get_vault_pass.sh`** — Retrieves Ansible Vault password from pass

### Documentation
- **`docs/VM_SETUP.md`** — Step-by-step guide for building the control VM

## Workflow

### Phase 1: Local Demo (no internet)

```bash
# On the host: create 3 local target VMs
bin/create_target_vms.sh

# From control VM: update inventory with local VM IPs
bin/update_local_inventory.sh

# Initial setup as root
ansible-playbook add_ansible_user.yml

# Harden SSH
ansible-playbook sshd_hardening-servers.yml

# Verify
ansible-playbook ping-servers.yml
ansible servers -m setup -a "filter=ansible_distribution*"
```

### Phase 2: Cloud Demo (extends Phase 1)

```bash
# From control VM: provision DO droplets
export TF_VAR_do_token=$(pass digitalocean/api_token)
cd tofu && tofu init && tofu apply
cd ..

# Update inventory with DO droplet IPs
bin/update_inventory.sh

# Same playbooks, cloud targets
ansible-playbook add_ansible_user.yml
ansible-playbook sshd_hardening-servers.yml
ansible-playbook ping-servers.yml
ansible servers -m setup -a "filter=ansible_distribution*"
```

### Teardown

```bash
# Local targets (on host)
bin/destroy_target_vms.sh

# Cloud targets (from control VM)
bin/teardown.sh
```

## Security Best Practices

- **Ansible Vault** stores passwords encrypted at rest (`vault.yml`)
- **pass + GPG** manages the vault password — no plaintext secrets on disk
- **SSH hardening** — root login disabled, password auth disabled after initial setup
- **OpenTofu sensitive variables** — API token never shown in plan/apply output
- **Local-first** — Phase 1 runs entirely offline, no cloud credentials needed

## License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**. See the `LICENSE` file for details.
