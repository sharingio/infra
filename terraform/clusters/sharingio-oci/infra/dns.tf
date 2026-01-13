# DNS records for cluster NODES
# Uses RFC 2136 dynamic DNS updates to Technitium
#
# Service records (wildcard, ns, k8s, wireguard) are in k8s/dns.tf

# Control plane node A records
resource "dns_a_record_set" "controlplane" {
  for_each = module.cluster.controlplane_nodes

  zone      = "${var.domain}."
  name      = each.key # pet name like "handy-monkey"
  addresses = [each.value.public_ip]
  ttl       = 300
}

# Worker node A records
resource "dns_a_record_set" "worker" {
  for_each = module.cluster.worker_nodes

  zone      = "${var.domain}."
  name      = each.key # pet name like "adequate-mammal"
  addresses = [each.value.public_ip]
  ttl       = 300
}

# API server record (needed for kubeconfig to work)
# This uses the reserved apiserver IP, not a node IP
resource "dns_a_record_set" "k8s" {
  zone      = "${var.domain}."
  name      = "k8s"
  addresses = [module.cluster.cluster_apiserver_ip]
  ttl       = 300
}
