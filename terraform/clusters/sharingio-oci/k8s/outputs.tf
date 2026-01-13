# Outputs from k8s layer

output "authentik_bootstrap_token" {
  value     = module.k8s_bootstrap.authentik_bootstrap_token
  sensitive = true
}

output "flux_path" {
  value = flux_bootstrap_git.this.path
}
