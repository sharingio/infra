# ConfigMap for cluster IPs used by Flux variable substitution
resource "kubernetes_config_map_v1" "cluster_ips" {
  metadata {
    name      = "cluster-ips"
    namespace = "flux-system"
  }

  data = {
    DNS_IP       = var.dns_ip
    INGRESS_IP   = var.ingress_ip
    WIREGUARD_IP = var.wg_ip
    APISERVER_IP = var.apiserver_ip
    DOMAIN       = var.domain
  }
}
