# Provider requirements for OCI + Talos infrastructure

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
    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
  }

  backend "http" {
    update_method = "PUT"
  }
}
