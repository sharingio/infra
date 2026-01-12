output "factory_disk_image" {
  value = data.talos_image_factory_urls.this.urls.disk_image
}

output "load_balancer_ip" {
  value = oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.ip_addresses[0].ip_address
}

output "talosconfig_bootstrap" {
  description = "Talosconfig with IPs for initial bootstrap"
  value       = data.talos_client_configuration.talosconfig.talos_config
  sensitive   = true
}

output "talos_client_ca" {
  description = "Talos client CA certificate (base64)"
  value       = talos_machine_secrets.machine_secrets.client_configuration.ca_certificate
  sensitive   = true
}

output "talos_client_crt" {
  description = "Talos client certificate (base64)"
  value       = talos_machine_secrets.machine_secrets.client_configuration.client_certificate
  sensitive   = true
}

output "talos_client_key" {
  description = "Talos client key (base64)"
  value       = talos_machine_secrets.machine_secrets.client_configuration.client_key
  sensitive   = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  sensitive = true
}

output "kubeconfig_ca_certificate" {
  value     = talos_cluster_kubeconfig.kubeconfig.kubernetes_client_configuration.ca_certificate
  sensitive = true
}

output "kubeconfig_client_key" {
  value     = talos_cluster_kubeconfig.kubeconfig.kubernetes_client_configuration.client_key
  sensitive = true
}

output "kubeconfig_client_certificate" {
  value     = talos_cluster_kubeconfig.kubeconfig.kubernetes_client_configuration.client_certificate
  sensitive = true
}

output "kubeconfig_host" {
  value     = talos_cluster_kubeconfig.kubeconfig.kubernetes_client_configuration.host
  sensitive = true
}

output "oci_cloud_provider_config" {
  value     = local.oci_cloud_provider_config
  sensitive = true
}

output "cilium_yaml" {
  value     = data.helm_template.cilium.manifest
  sensitive = true
}

# Reserved IPs that survive cluster rebuilds
output "cluster_apiserver_ip" {
  description = "Control plane load balancer IP"
  value       = oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.ip_addresses[0].ip_address
}

output "cluster_ingress_ip" {
  description = "Reserved IP for ingress (HTTP/HTTPS)"
  value       = oci_core_public_ip.ingress.ip_address
}

output "cluster_dns_ip" {
  description = "Reserved IP for DNS server"
  value       = oci_core_public_ip.dns.ip_address
}

output "cluster_wireguard_ip" {
  description = "Reserved IP for Wireguard VPN"
  value       = oci_core_public_ip.wireguard.ip_address
}

# Node information for DNS records
output "controlplane_nodes" {
  description = "Control plane node names and IPs"
  value = {
    for idx, instance in oci_core_instance.controlplane : random_pet.controlplane[idx].id => {
      hostname   = "${random_pet.controlplane[idx].id}.${var.domain}"
      public_ip  = instance.public_ip
      private_ip = instance.private_ip
    }
  }
}

output "worker_nodes" {
  description = "Worker node names and IPs"
  value = {
    for idx, instance in oci_core_instance.worker : random_pet.worker[idx].id => {
      hostname   = "${random_pet.worker[idx].id}.${var.domain}"
      public_ip  = instance.public_ip
      private_ip = instance.private_ip
    }
  }
}
