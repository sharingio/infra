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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "> 0.0.0"
    }
  }
  required_version = ">= 1.8"
}
