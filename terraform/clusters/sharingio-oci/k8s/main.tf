# sharingio-oci k8s configuration
#
# This layer configures:
# - K8s ConfigMaps, Secrets, Namespaces
# - Flux GitOps bootstrap
# - Service DNS records
# - Authentik configuration
#
# Requires kubeconfig from infra/ layer or existing cluster

module "k8s_bootstrap" {
  source = "../../../modules/k8s-bootstrap"

  # Reserved IPs for service assignment
  ingress_ip   = var.cluster_ips.ingress
  dns_ip       = var.cluster_ips.dns
  wg_ip        = var.cluster_ips.wireguard
  apiserver_ip = var.cluster_ips.apiserver

  acme_email_address     = var.admin_email
  rfc2136_nameserver     = var.rfc2136_nameserver
  rfc2136_tsig_keyname   = var.rfc2136_tsig_keyname
  rfc2136_tsig_key       = var.rfc2136_tsig_key
  rfc2136_tsig_algorithm = "HMACSHA256"
  domain                 = var.domain
  coder_version          = var.coder_version
  authentik_version      = var.authentik_version

  # Coder GitHub OAuth
  coder_oauth2_github_client_id     = var.coder_oauth2_github_client_id
  coder_oauth2_github_client_secret = var.coder_oauth2_github_client_secret
  coder_gitauth_0_client_id         = var.coder_gitauth_0_client_id
  coder_gitauth_0_client_secret     = var.coder_gitauth_0_client_secret

  providers = {
    kubernetes = kubernetes
    random     = random
  }
}

# Flux GitOps bootstrap
data "github_repository" "this" {
  full_name = "${var.github_org}/${var.github_repository}"
}

resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "this" {
  title      = "Flux - sharingio-oci"
  repository = var.github_repository
  key        = tls_private_key.flux.public_key_openssh
  read_only  = "false"
}

resource "flux_bootstrap_git" "this" {
  depends_on = [github_repository_deploy_key.this, module.k8s_bootstrap]

  embedded_manifests = true
  path               = "flux/clusters/sharingio-oci"
  components_extra   = ["image-reflector-controller", "image-automation-controller"]
}

# Authentik configuration - commented out until authentik is deployed by Flux
# Run as separate step: tofu apply -target=module.authentik_config
#
# module "authentik_config" {
#   source = "../../../authentik-config"
#
#   github_oauth_app_id                = var.authentik_github_oauth_app_id
#   github_oauth_app_secret            = var.authentik_github_oauth_app_secret
#   authentik_coder_oidc_client_id     = module.k8s_bootstrap.authentik_coder_oidc_client_id
#   authentik_coder_oidc_client_secret = module.k8s_bootstrap.authentik_coder_oidc_client_secret
#   authentik_bootstrap_token          = module.k8s_bootstrap.authentik_bootstrap_token
#   domain                             = var.domain
#
#   providers = {
#     authentik  = authentik
#     flux       = flux
#     kubernetes = kubernetes
#   }
#
#   depends_on = [module.k8s_bootstrap, flux_bootstrap_git.this]
# }
