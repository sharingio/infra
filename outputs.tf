output "cloudnative-coop-talosconfig" {
  value     = module.cloudnative-coop.talosconfig
  sensitive = true
}

output "cloudnative-coop-kubeconfig" {
  value     = module.cloudnative-coop.kubeconfig.kubeconfig_raw
  sensitive = true
}

output "cloudnative-coop-akadmin-password" {
  value     = module.cloudnative-coop-manifests.authentik_bootstrap_password
  sensitive = true
}

output "cloudnative-coop-akadmin-token" {
  value     = module.cloudnative-coop-manifests.authentik_bootstrap_token
  sensitive = true
}

output "cloudnative-coop-cluster-apiserver-ip" {
  value = module.cloudnative-coop.cluster_apiserver_ip
}

output "cloudnative-coop-cluster-ingress-ip" {
  value = module.cloudnative-coop.cluster_ingress_ip
}
output "coder_admin_email" {
  value = module.cloudnative-coop-manifests.coder_admin_email
}
output "coder_admin_password" {
  value     = module.cloudnative-coop-manifests.coder_admin_password
  sensitive = true
}
