locals {
  # Reserved IPs from OCI module - these survive cluster rebuilds
  ingress_ipv4   = module.cluster-sharingio-oci.cluster_ingress_ip
  dns_ipv4       = module.cluster-sharingio-oci.cluster_dns_ip
  wireguard_ipv4 = module.cluster-sharingio-oci.cluster_wireguard_ip
  apiserver_ipv4 = module.cluster-sharingio-oci.cluster_apiserver_ip
}
