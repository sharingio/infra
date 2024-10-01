output "factory_disk_image" {
  value = module.cluster-sharingio-oci.factory_disk_image
}

output "load_balancer_ip" {
  value = module.cluster-sharingio-oci.load_balancer_ip
}

output "talosconfig" {
  value     = module.cluster-sharingio-oci.talosconfig
  sensitive = true
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
