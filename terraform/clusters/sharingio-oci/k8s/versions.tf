# Provider requirements for k8s configuration layer

terraform {
  required_version = ">= 1.8"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "~> 1.4.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.4.0"
    }
    # authentik provider - uncomment when authentik is deployed
    # authentik = {
    #   source  = "goauthentik/authentik"
    #   version = "~> 2025.10.0"
    # }
    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "> 0.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.0"
    }
  }

  backend "http" {
    update_method = "PUT"
  }
}
