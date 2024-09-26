terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "6.7.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~>0.6.0-beta.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "> 0.0.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "~>1.3.0"
    }
    github = {
      source  = "integrations/github"
      version = "~>6.3.0"
    }
  }
  required_version = ">= 1.2"
  backend "kubernetes" {
    secret_suffix = "cluster-state"
    namespace     = "tfstate"
    config_path   = "~/.kube/config-fop"
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
    config_path = local_file.kubeconfig.filename
  }
  git = {
    url = "ssh://git@github.com/${var.github_org}/${var.github_repository}.git"
    ssh = {
      username    = "git"
      private_key = tls_private_key.flux.private_key_pem
    }
  }
}
