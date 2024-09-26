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
  }
  required_version = ">= 1.2"
}
