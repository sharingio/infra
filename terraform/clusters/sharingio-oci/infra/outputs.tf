# Outputs for k8s/ layer to consume

output "kubeconfig_path" {
  description = "Path to generated kubeconfig file"
  value       = local_file.kubeconfig.filename
}

output "talosconfig_path" {
  description = "Path to generated talosconfig file"
  value       = local_file.talosconfig.filename
}

output "cluster_ips" {
  description = "Reserved IPs for services"
  value = {
    ingress   = module.cluster.cluster_ingress_ip
    dns       = module.cluster.cluster_dns_ip
    apiserver = module.cluster.cluster_apiserver_ip
    wireguard = module.cluster.cluster_wireguard_ip
  }
}

# Raw kubeconfig for direct use
output "kubeconfig" {
  description = "Kubeconfig content"
  value       = module.cluster.kubeconfig
  sensitive   = true
}

output "kubeconfig_host" {
  value     = module.cluster.kubeconfig_host
  sensitive = true
}

output "kubeconfig_ca_certificate" {
  value     = module.cluster.kubeconfig_ca_certificate
  sensitive = true
}

output "kubeconfig_client_certificate" {
  value     = module.cluster.kubeconfig_client_certificate
  sensitive = true
}

output "kubeconfig_client_key" {
  value     = module.cluster.kubeconfig_client_key
  sensitive = true
}

# Node information
output "controlplane_nodes" {
  description = "Control plane nodes with hostnames and IPs"
  value       = module.cluster.controlplane_nodes
}

output "worker_nodes" {
  description = "Worker nodes with hostnames and IPs"
  value       = module.cluster.worker_nodes
}

# For debugging
output "factory_disk_image" {
  value = module.cluster.factory_disk_image
}

output "load_balancer_ip" {
  value = module.cluster.load_balancer_ip
}

output "cilium_yaml" {
  value     = module.cluster.cilium_yaml
  sensitive = true
}

output "oci_cloud_provider_config" {
  value     = module.cluster.oci_cloud_provider_config
  sensitive = true
}
