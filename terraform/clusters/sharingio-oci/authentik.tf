# Authentik configuration after bootstrap
# Sets up GitHub OAuth federation, Coder OIDC, etc.

module "cluster-authentik-config" {
  source = "../../authentik-config"

  github_oauth_app_id                = var.authentik_github_oauth_app_id
  github_oauth_app_secret            = var.authentik_github_oauth_app_secret
  authentik_coder_oidc_client_id     = module.cluster-sharingio-oci-manifests.authentik_coder_oidc_client_id
  authentik_coder_oidc_client_secret = module.cluster-sharingio-oci-manifests.authentik_coder_oidc_client_secret
  authentik_bootstrap_token          = module.cluster-sharingio-oci-manifests.authentik_bootstrap_token
  domain                             = var.domain

  providers = {
    authentik  = authentik
    flux       = flux
    kubernetes = kubernetes.cluster-sharingio-oci
  }

  depends_on = [module.cluster-sharingio-oci-manifests, flux_bootstrap_git.this]
}
