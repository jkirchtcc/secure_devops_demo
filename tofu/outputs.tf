output "droplet_ips" {
  description = "Map of server names to their public IPv4 addresses"
  value = {
    for name, droplet in digitalocean_droplet.servers : name => droplet.ipv4_address
  }
}
