# Demo Slide Checklist

General comment: Can I screenshot images from my original presentation to use to replace ones that I don't like? I can handle the screenshot part, but how should they get labeled so you could use them?

Add your issues under each slide. Format: `- [ ] description of problem`

---

## Part 1: SSH Setup

- [ ] **Slide 1** — Title - Ok
- [ ] **Slide 2** — Today's Topics - Can you make the font size bigger?
- [ ] **Slide 3** — *(Part 1 section  - Ok
- [ ] **Slide 4** — Generate SSH Keys *(has demo)* - Most of the text in the code window is black on a black background and can't be read. The actual, command in the demo is: ssh-keygen -t ed25519 -C DemoSSHKey -f /home/ansible_user/.ssh/DemoSSHKey -N" the slides do NOT have the -N.
- [ ] **Slide 5** — Upload SSH Public Key - text in the code window is black on a black background and can't be read. Can you make the font for the bullets bigger?
- [ ] **Slide 6** — RSA 4096 vs ED25519 - Can you make the font for code bigger?
- [ ] **Slide 7** — Configure SSH Client *(has demo)* - text in the code window is black on a black background and can't be read. At this point in the demo should the user be root? That's what's on the slide.
- [ ] **Slide 8** — SSH to ansible, part 1 - text in the code window is black on a black background and can't be read. Can the code font size be bigger. There is also a stray red arrow, you can delete.
- [ ] **Slide 9** — CyberSecurity Time - Can you increase the font size
- [ ] **Slide 10** — Update ssh config - Can you increase the font size. text in the code window is black on a black background and can't be read.
- [ ] **Slide 11** — SSH Setup Summary - Can you increase the font size

---

## Part 2: Ansible Setup

- [ ] **Slide 12** — *(Part 2 section card)* - ok
- [ ] **Slide 13** — Install Ansible - Can you increase the font size
- [ ] **Slide 14** — Logout & Login - Can you increase the font size
- [ ] **Slide 15** — Ansible Installed *(has demo)* - ok
- [ ] **Slide 16** — *(Part 3 section card)* - ok

---

## Part 3: Ansible Demo

- [ ] **Slide 17** — Our First Ansible Playbook *(has demo)* - slide ok, demo not in color
- [ ] **Slide 18** — ansible.cfg - does the real ansible.cfg match what's on the slide in the code block? same question for the ansible-playbook ping.yml output in the codeblock. 
- [ ] **Slide 19** — Update ansible with Ansible *(has demo)* - slide ok, demo not in color
- [ ] **Slide 20** — Ansible with sudo - ok

---

## Part 4: Storing Secrets

- [ ] **Slide 21** — Storing Secrets in Ansible *(Part 4 section card)* - Font bigger?
- [ ] **Slide 22** — Ansible Vault *(has demo)* - Font bigger? 
- [ ] **Slide 23** — Let's use pass *(has demo)* - Font bigger? The get vault pass.sh doesn't show the underscores.
- [ ] **Slide 24** — pass uses GPG - font bigger? The the outputs are not color.
- [ ] **Slide 25** — Update ansible.cfg for pass *(has demo)* - text in the code window is black on a black background and can't be read. 
- [ ] **Slide 26** — Update our update.yml - Font bigger?
- [ ] **Slide 27** — Okay... - Font bigger?

---

## Part 5: SSHD Hardening

- [ ] **Slide 28** — Let's spin up more machines *(has demo)* - Font bigger? You should show the inventory before and after as code blocks. Demo: I don't understand what's the first part is doing, the after is good.
- [ ] **Slide 29** — Ansible to update .bashrc *(has demo)* - Font Bigger?  text in the code window is black on a black background and can't be read. Demo: underscores not shown in the cat add_ssh_key.yml. Color would be nice.
- [ ] **Slide 30** — Idempotent *(has demo)* - font bigger in code block. Bigger issue, the idempotent thing is not shown (because bashrc change must have already been setup). Demo: not run twice, and not color. 
- [ ] **Slide 31** — Now we are ready *(has demo)* - font bigger in code block? Demo: does not show having to type "yes" each time for the first time ssh'ing to the server, before the warnings / fatal messages go away. Needs to be redone showing that.
- [ ] **Slide 32** — Add ansible_user to servers *(has demo)* - Font bigger for the YAML code block. Demo: underscores are not showing up. color please?
- [ ] **Slide 33** — Switch SSH config to ansible_user *(has demo)* - text in the code window is black on a black background and can't be read. Font bigger?
- [ ] **Slide 34** — Verify ansible_user can connect *(has demo)* color?
- [ ] **Slide 35** — SSHD Hardening *(has demo)* okay Demo: color?
- [ ] **Slide 36** — Now we can ping servers *(has demo)* Demo: color?

---

## Part 6: Ad-hoc Commands

- [ ] **Slide 37** — Ad-hoc commands *(has demo)* Font bigger? Demo: Does not show the two commands from the slide. Update the slide with the additional command shown. 
- [ ] **Slide 38** — Summary - Font bigger?
- [ ] **Slide 39** — Closing - okay


## Additional Issues
- [ ] **Slide 17** - Our First Ansible Playbook - You should show the command above the text block: cat inventory.ini, cat ping.yml, and ansible-playbook -i inventory.ini ping.yml Demo: that should run those three commands, with a brief pause between each one. Also, because you ran the ansible-playbook with the inventory.ini and warnings turned off they are not shown in the demo. color please?
- [ ] **Slide 19** - Update ansible with Ansible - Demo: The cat update.yml is good, but the ansible-playbook update.yml is not. It was supposed to fail because it needed the sudo password. (which we handle in the next slide).
- [ ] **Slide Demo**  - Let's use pass - Demo: should be running ./install_setup_pass.sh, then showing pass ansible/vault_password
- [ ] **Slide 25** - Update ansible.cfg for pass - the vault_password_file = /home/ansible_user/bin/get_vault_pass.sh (the full path) Demo: what is the [ssh_connection]  ssh_args = -o StrictHostKeyChecking=accept-new in the ansible.cfg? I don't remember that in my version? 
- [ ] **Slide 28** - Let's spin up more machines - You do not show the command you used to spin up the three new machines, how are my public key getting added to those? Demo: it just shows some blah stuff in the begining, then the AFTER: inventory.ini. I think it needs to show the BEFORE: inventory.ini with just localhost, then show how you spin up the new machines, then update the inventory, and show the AFTER
- [ ] **New Slide after Slide 32 - Add ansible_user to servers *(and after demo)* - New slide title: Wait, what?: 
  
