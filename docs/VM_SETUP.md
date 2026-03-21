# Control VM Setup Guide

Step-by-step guide for building the QEMU/KVM control VM used in the CyberForge 2026 demo.

## 1. Install QEMU/KVM on the Host

On the presenter laptop (korell):

```bash
bin/install_qemu_kvm.sh
```

Log out and back in for group membership to take effect.

Verify:

```bash
virsh list --all
virt-manager  # should launch the GUI
```

## 2. Create the Control VM

```bash
bin/create_control_vm.sh
```

This downloads the Ubuntu 24.04 cloud image and creates a VM with 2 GB RAM, 2 vCPUs, 20 GB disk, and an `ansible_user` account.

After it boots, set a password for `ansible_user`:

```bash
virsh console control-vm
# Log in as ansible_user (no password yet)
passwd
# Ctrl+] to exit console
```

Then SSH in:

```bash
ssh ansible_user@<control-vm-ip>
```

## 3. Clone the Repo Inside the VM

```bash
sudo apt-get install -y git
git clone https://github.com/jkirchtcc/secure_devops_demo.git
cd secure_devops_demo
```

## 4. Run the Setup Script

```bash
bin/setup_control_vm.sh
```

This installs everything: Ansible, OpenTofu, pass + GPG, and prompts for the vault password.

## 5. Generate SSH Key

If the setup script didn't generate one (or you skipped it):

```bash
ssh-keygen -t ed25519 -C "DemoSSHKey" -f ~/.ssh/DemoSSHKey
```

Use a passphrase.

Copy the public key to the host so `create_target_vms.sh` can embed it in cloud-init:

```bash
# From the host, copy the key
scp ansible_user@<control-vm-ip>:~/.ssh/DemoSSHKey.pub ~/.ssh/DemoSSHKey.pub
```

Or if using a shared folder, just ensure `~/.ssh/DemoSSHKey.pub` exists on the host.

## 6. Store DigitalOcean Token (Phase 2 Only)

```bash
pass insert digitalocean/api_token
```

Paste the token when prompted. This is only needed for the cloud demo (Phase 2).

## 7. Snapshot

Take a snapshot in virt-manager: `clean-setup`.

This is the restore point if anything goes wrong during demo prep.

## 8. Create Local Target VMs

On the host (not inside the control VM):

```bash
bin/create_target_vms.sh
```

This downloads Ubuntu cloud images and creates 3 target VMs (target-1, target-2, target-3) with the SSH key in authorized_keys.

## 9. Test the Full Workflow

From the control VM:

```bash
# Update inventory with local VM IPs
bin/update_local_inventory.sh

# Test connectivity as root
ansible servers -m ping -u root

# Run the full playbook sequence
ansible-playbook add_ssh_key.yml
ansible-playbook update.yml
ansible-playbook add_ansible_user.yml
ansible-playbook sshd_hardening-servers.yml
ansible-playbook ping-servers.yml

# Verify all 3 Ubuntu versions
ansible servers -m setup -a "filter=ansible_distribution*"
```

## 10. Demo Day Snapshots

After everything works:

1. Destroy local targets: `bin/destroy_target_vms.sh` (on host)
2. Snapshot control VM as `pre-talk-clean`
3. Recreate targets and run full demo
4. Snapshot control VM as `pre-talk-with-infra` (fallback)
