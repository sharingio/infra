# DNS records for cluster nodes and services
# Uses RFC 2136 dynamic DNS updates to Technitium
#
# This is for self-hosted authoritative DNS (sharing.io)
# The registrar NS records point to ns.sharing.io

# Control plane node A records
resource "dns_a_record_set" "controlplane" {
  for_each = module.cluster-sharingio-oci.controlplane_nodes

  zone      = "${var.domain}."
  name      = each.key # pet name like "handy-monkey"
  addresses = [each.value.public_ip]
  ttl       = 300
}

# Worker node A records
resource "dns_a_record_set" "worker" {
  for_each = module.cluster-sharingio-oci.worker_nodes

  zone      = "${var.domain}."
  name      = each.key # pet name like "adequate-mammal"
  addresses = [each.value.public_ip]
  ttl       = 300
}

# Service records
# Note: Apex domain (@) must be managed via Technitium API directly
# since the hashicorp/dns provider doesn't support empty name for RFC 2136

resource "dns_a_record_set" "wildcard" {
  zone      = "${var.domain}."
  name      = "*"
  addresses = [local.ingress_ipv4]
  ttl       = 300
}

resource "dns_a_record_set" "ns" {
  zone      = "${var.domain}."
  name      = "ns"
  addresses = [local.dns_ipv4]
  ttl       = 300
}

resource "dns_a_record_set" "k8s" {
  zone      = "${var.domain}."
  name      = "k8s"
  addresses = [local.apiserver_ipv4]
  ttl       = 300
}

resource "dns_a_record_set" "wireguard" {
  zone      = "${var.domain}."
  name      = "wireguard"
  addresses = [local.wireguard_ipv4]
  ttl       = 300
}
