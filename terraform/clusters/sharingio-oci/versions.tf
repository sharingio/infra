# Provider requirements and backend for sharingio-oci cluster

terraform {
  required_version = ">= 1.8"

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
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
  }

  # Remote backend using OCI Object Storage via HTTP (Pre-Authenticated Request)
  # State is stored in: sharingio-tfstate bucket in OCI
  #
  # NOTE: HTTP backend does not support state locking. Coordinate access.
  #
  # SETUP: Set TF_HTTP_ADDRESS environment variable with your PAR URL
  # See .envrc for the current PAR URL
  backend "http" {
    update_method = "PUT"
  }
}
