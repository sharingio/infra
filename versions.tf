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
