terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "6.7.0"
    }
  }
}

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_ocid" {}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
  fingerprint      = var.fingerprint
  region           = var.region
}

resource "oci_objectstorage_bucket" "tfstate" {
  compartment_id = var.compartment_ocid
  name           = "sharingio-tfstate"
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  access_type    = "NoPublicAccess"
  versioning     = "Enabled"
}

data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_ocid
}

output "bucket_name" {
  value = oci_objectstorage_bucket.tfstate.name
}

output "namespace" {
  value = data.oci_objectstorage_namespace.ns.namespace
}

output "bucket_endpoint" {
  value = "https://objectstorage.${var.region}.oraclecloud.com"
}
