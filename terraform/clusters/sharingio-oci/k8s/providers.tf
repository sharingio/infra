# Provider configurations for k8s layer
#
# Uses kubeconfig from infra/ layer or existing cluster

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

provider "flux" {
  kubernetes = {
    config_path = var.kubeconfig_path
  }
  git = {
    url = "ssh://git@github.com/${var.github_org}/${var.github_repository}.git"
    ssh = {
      username    = "git"
      private_key = tls_private_key.flux.private_key_pem
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_org
}

# Authentik provider - commented out until authentik is deployed by Flux
# Run authentik_config as a separate step after Flux deploys authentik
#
# provider "authentik" {
#   url   = "https://sso.${var.domain}"
#   token = module.k8s_bootstrap.authentik_bootstrap_token
# }

provider "dns" {
  update {
    server        = var.rfc2136_nameserver
    port          = var.rfc2136_port
    key_name      = var.rfc2136_tsig_keyname
    key_secret    = var.rfc2136_tsig_key
    key_algorithm = "hmac-sha256"
  }
}
