# DNS records for cluster SERVICES
# Uses RFC 2136 dynamic DNS updates to Technitium
#
# Node records (controlplane, worker) are in infra/dns.tf

# Wildcard for ingress
resource "dns_a_record_set" "wildcard" {
  zone      = "${var.domain}."
  name      = "*"
  addresses = [var.cluster_ips.ingress]
  ttl       = 300
}

# DNS server
resource "dns_a_record_set" "ns" {
  zone      = "${var.domain}."
  name      = "ns"
  addresses = [var.cluster_ips.dns]
  ttl       = 300
}

# VPN
resource "dns_a_record_set" "wireguard" {
  zone      = "${var.domain}."
  name      = "wireguard"
  addresses = [var.cluster_ips.wireguard]
  ttl       = 300
}
