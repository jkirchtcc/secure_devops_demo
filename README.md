# Ansible Project for Secure Environment Setup

This Ansible project demonstrates how to securely set up an environment for using Ansible without storing plain text passwords. It covers user management, SSH key configuration, SSH hardening, and system updates for Ubuntu servers (20.04, 22.04, 24.04).

## Prerequisites

- **Ansible** must be installed on the control machine. Install it using the provided script:
  ```bash
  ./install_ansible.sh
  ```
- **SSH Key**: Ensure that `DemoSSHKey` and `DemoSSHKey.pub` are present in `~/.ssh/`.
- **Ansible Vault**: Store sensitive information like passwords in `vault.yml` to avoid plain text storage.

## Files Overview

- **`ansible.cfg`**: Configures Ansible settings such as inventory location and SSH options.
- **`add_ansible_user.yml`**: Adds an `ansible_user`, sets up a hashed password, and configures SSH access securely.
- **`add_ssh_key.yml`**: Ensures `ssh-agent` is running and loads the `DemoSSHKey` automatically.
- **`ping-servers.yml`**: Verifies connectivity to hosts defined in the `servers` group.
- **`ping.yml`**: Pings `localhost` to confirm Ansible's local setup.
- **`sshd_hardening-servers.yml`**: Secures SSH configurations, including disabling root login and enabling public key authentication.
- **`update.yml`**: Updates and upgrades packages on the `localhost`.

## Usage

1. **Configure Ansible Inventory**: Define your servers in the `inventory` file specified in `ansible.cfg`.

2. **Add a User and Configure SSH Access**:
   Run the following command to add a user with SSH access:
   ```bash
   ansible-playbook add_ansible_user.yml
   ```

3. **Set Up SSH Key**:
   To ensure the SSH key is loaded automatically, run:
   ```bash
   ansible-playbook add_ssh_key.yml
   ```

4. **Update Packages**:
   Update and upgrade packages on the local machine:
   ```bash
   ansible-playbook update.yml
   ```

5. **Harden SSH Configuration**:
   Apply secure SSH settings on the servers:
   ```bash
   ansible-playbook sshd_hardening-servers.yml
   ```

6. **Verify Server Connectivity**:
   Check connectivity of all servers in the `servers` group:
   ```bash
   ansible-playbook ping-servers.yml
   ```

## Security Best Practices

- Use **Ansible Vault** to store passwords securely. Update `vault.yml` with encrypted values for sensitive information like `ansible_user_password`.
- This setup emphasizes eliminating plain text passwords and relies on secure methods like SSH key-based authentication.

## License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**. See the `LICENSE` file for more details.
