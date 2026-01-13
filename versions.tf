terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.29"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.9.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "> 0.0.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "~> 1.4.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "~> 2025.10.0"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.4.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.8"

  # Remote backend using OCI Object Storage via HTTP (Pre-Authenticated Request)
  # State is stored in: sharingio-tfstate bucket in OCI
  # Backups at: sharingio-tfstate/backups/
  #
  # NOTE: HTTP backend does not support state locking. Coordinate access.
  #
  # SETUP: Set TF_HTTP_ADDRESS environment variable with your PAR URL:
  #   export TF_HTTP_ADDRESS="https://axe608t7iscj.objectstorage.us-phoenix-1.oci.customer-oci.com/p/<PAR_TOKEN>/n/axe608t7iscj/b/sharingio-tfstate/o/terraform.tfstate"
  #
  # To create/renew PAR (valid 1 year):
  #   oci os preauth-request create --bucket-name sharingio-tfstate --namespace axe608t7iscj \
  #     --name terraform-state-rw --access-type ObjectReadWrite \
  #     --time-expires $(date -d "+365 days" +%Y-%m-%dT%H:%M:%SZ) --object-name terraform.tfstate
  #
  # The full-path from output goes in TF_HTTP_ADDRESS
  backend "http" {
    update_method = "PUT"
  }
}

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
    # config_path = local_file.kubeconfig.filename
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
  alias = "cluster-sharingio-oci"
  # config_path = "./kubeconfig"
  # We use an IP here to speed things up, the first nome name might work as well
  host                   = module.cluster-sharingio-oci.kubeconfig_host
  client_certificate     = base64decode(module.cluster-sharingio-oci.kubeconfig_client_certificate)
  client_key             = base64decode(module.cluster-sharingio-oci.kubeconfig_client_key)
  cluster_ca_certificate = base64decode(module.cluster-sharingio-oci.kubeconfig_ca_certificate)
}
provider "authentik" {
  url   = "https://sso.${var.domain}"
  token = module.cluster-sharingio-oci-manifests.authentik_bootstrap_token
  # Optionally set insecure to ignore TLS Certificates
  # insecure = true
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
