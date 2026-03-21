resource "digitalocean_ssh_key" "demo" {
  name       = "DemoSSHKey"
  public_key = file(pathexpand(var.ssh_key_path))
}

locals {
  servers = {
    server1 = "ubuntu-24-04-x64"
    server2 = "ubuntu-22-04-x64"
    server3 = "ubuntu-20-04-x64"
  }
}

resource "digitalocean_droplet" "servers" {
  for_each = local.servers

  name     = each.key
  image    = each.value
  size     = var.droplet_size
  region   = var.region
  ssh_keys = [digitalocean_ssh_key.demo.fingerprint]
  tags     = ["cyberforge-demo"]
}
