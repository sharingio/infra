output "load_balancer_ip" {
  value = oci_load_balancer_load_balancer.cp_load_balancer.ip_address_details[0].ip_address
}

output "talosconfig" {
  value     = data.talos_client_configuration.talosconfig.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  sensitive = true
}