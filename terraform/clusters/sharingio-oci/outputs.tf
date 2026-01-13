output "factory_disk_image" {
  value = module.cluster-sharingio-oci.factory_disk_image
}

output "load_balancer_ip" {
  value = module.cluster-sharingio-oci.load_balancer_ip
}

output "talosconfig" {
  description = "Talosconfig with DNS hostnames (stable)"
  value       = local_file.talosconfig.content
  sensitive   = true
}

output "talosconfig_bootstrap" {
  description = "Talosconfig with IPs (for bootstrap)"
  value       = module.cluster-sharingio-oci.talosconfig_bootstrap
  sensitive   = true
}

output "kubeconfig" {
  value     = module.cluster-sharingio-oci.kubeconfig
  sensitive = true
}

output "kubeconfig_host" {
  value     = module.cluster-sharingio-oci.kubeconfig_host
  sensitive = true
}

output "oci_cloud_provider_config" {
  value     = module.cluster-sharingio-oci.oci_cloud_provider_config
  sensitive = true
}

output "cilium_yaml" {
  value     = module.cluster-sharingio-oci.cilium_yaml
  sensitive = true
}

# Reserved IPs for registrar glue records and DNS configuration
output "cluster_ips" {
  description = "Reserved IPs that survive cluster rebuilds"
  value = {
    dns       = module.cluster-sharingio-oci.cluster_dns_ip
    ingress   = module.cluster-sharingio-oci.cluster_ingress_ip
    wireguard = module.cluster-sharingio-oci.cluster_wireguard_ip
    apiserver = module.cluster-sharingio-oci.cluster_apiserver_ip
  }
}

# Node information
output "controlplane_nodes" {
  description = "Control plane nodes with hostnames and IPs"
  value       = module.cluster-sharingio-oci.controlplane_nodes
}

output "worker_nodes" {
  description = "Worker nodes with hostnames and IPs"
  value       = module.cluster-sharingio-oci.worker_nodes
}
