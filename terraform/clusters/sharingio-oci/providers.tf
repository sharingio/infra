# Provider configurations for sharingio-oci cluster

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
  fingerprint      = var.fingerprint
  region           = var.region
}

provider "github" {
  token = var.github_token
  owner = var.github_org
}

provider "flux" {
  kubernetes = {
    host                   = module.cluster-sharingio-oci.kubeconfig_host
    client_certificate     = base64decode(module.cluster-sharingio-oci.kubeconfig_client_certificate)
    client_key             = base64decode(module.cluster-sharingio-oci.kubeconfig_client_key)
    cluster_ca_certificate = base64decode(module.cluster-sharingio-oci.kubeconfig_ca_certificate)
  }
  git = {
    url = "ssh://git@github.com/${var.github_org}/${var.github_repository}.git"
    ssh = {
      username    = "git"
      private_key = tls_private_key.flux.private_key_pem
    }
  }
}

provider "kubernetes" {
  alias                  = "cluster-sharingio-oci"
  host                   = module.cluster-sharingio-oci.kubeconfig_host
  client_certificate     = base64decode(module.cluster-sharingio-oci.kubeconfig_client_certificate)
  client_key             = base64decode(module.cluster-sharingio-oci.kubeconfig_client_key)
  cluster_ca_certificate = base64decode(module.cluster-sharingio-oci.kubeconfig_ca_certificate)
}

provider "authentik" {
  url   = "https://sso.${var.domain}"
  token = module.cluster-sharingio-oci-manifests.authentik_bootstrap_token
}

provider "dns" {
  update {
    server        = var.rfc2136_nameserver
    port          = var.rfc2136_port
    key_name      = var.rfc2136_tsig_keyname
    key_secret    = var.rfc2136_tsig_key
    key_algorithm = "hmac-sha256"
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
