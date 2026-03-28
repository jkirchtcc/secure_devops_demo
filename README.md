# Secure DevOps: Setting up a secure environment for Ansible

Demo project for CyberForge 2026 — covering SSH keys, GPG, pass, Ansible Vault, and sshd hardening with live Ansible playbooks.

## Architecture

Everything runs on a single presenter laptop using QEMU/KVM:

```
korell (presenter laptop, 192.168.122.1 via virbr0)
  └── QEMU/KVM
      ├── ansible (control VM, Ubuntu 24.04, 192.168.122.100)
      ├── target-1 (Ubuntu 24.04,  192.168.122.101)
      ├── target-2 (Ubuntu 22.04,  192.168.122.102)
      └── target-3 (Ubuntu 24.10,  192.168.122.103)
```

Parts 1–4 run on the control VM only. Parts 5–6 add the 3 target VMs.

## Prerequisites

- **QEMU/KVM** on the host — `bin/install_qemu_kvm.sh`
- **Control VM** — created with `bin/create_control_vm.sh`, configured with `bin/setup_control_vm.sh`
- **SSH Key** — `~/.ssh/DemoSSHKey` and `DemoSSHKey.pub` (with passphrase)
- **pass + GPG** — vault password stored in `pass` at `ansible/vault_password`

## Scripts

### Host (korell)
| Script | Purpose |
|--------|---------|
| `bin/install_qemu_kvm.sh` | Install QEMU/KVM and virt-manager |
| `bin/create_control_vm.sh` | Create the Ansible control VM |
| `bin/create_target_vms.sh` | Create 3 local target VMs from Ubuntu cloud images |
| `bin/destroy_target_vms.sh` | Tear down target VMs |
| `bin/reset_target_vms.sh` | Destroy and recreate target VMs (clean state) |
| `bin/setup_host_ssh.sh` | Write `~/.ssh/config` entry for `ssh ansible` |

### Control VM
| Script | Purpose |
|--------|---------|
| `bin/setup_control_vm.sh` | One-script control VM setup (Ansible, pass, GPG, SSH key) |
| `bin/install_ansible.sh` | Install Ansible via uv |
| `bin/install_setup_pass.sh` | Set up pass + GPG, store vault password |
| `bin/get_vault_pass.sh` | Retrieve vault password from pass (used by ansible.cfg) |
| `bin/update_local_inventory.sh` | Write `inventory.ini` with local VM IPs |
| `bin/update_ssh_config.sh` | Write `~/.ssh/config` entries for target servers |

### Demo and Recording
| Script | Purpose |
|--------|---------|
| `bin/demo.sh` | Interactive demo runner (all 6 parts) |
| `bin/record-slide.sh` | Record a single slide as asciinema cast + GIF |
| `start.sh` | Serve `docs/recordings/` locally for slide review |

## Ansible Playbooks

| Playbook | Purpose |
|----------|---------|
| `ping.yml` | Ping localhost (verify Ansible works) |
| `ping-servers.yml` | Ping all servers |
| `update.yml` | Apt update + upgrade on localhost |
| `add_ssh_key.yml` | Configure ssh-agent auto-start in `.bashrc` |
| `add_ansible_user.yml` | Create `ansible_user` on servers with SSH key and hashed password |
| `sshd_hardening-servers.yml` | Disable root login and password auth on servers |

## Workflow

```bash
# On korell: create 3 local target VMs
bin/create_target_vms.sh

# On control VM: populate inventory
bin/update_local_inventory.sh

# Run the demo (Parts 1–6)
bin/demo.sh
```

## Security Practices Demonstrated

- **ED25519 SSH keys** with passphrases, managed by ssh-agent
- **Ansible Vault** — secrets encrypted at rest (AES-256)
- **pass + GPG** — vault password stored encrypted, decrypted by gpg-agent
- **Non-root Ansible user** — `ansible_user` created with sudo, root login disabled after setup
- **sshd hardening** — `PermitRootLogin no`, `PasswordAuthentication no`, `PubkeyAuthentication yes`

## License

[GPL-3.0](LICENSE)
