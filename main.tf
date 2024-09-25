locals {
  talos_image_oci_bucket_url = "https://axe608t7iscj.objectstorage.us-phoenix-1.oci.customer-oci.com/n/axe608t7iscj/b/talos/o/talos-v1.7.6-oracle-arm64.oci"
}
module "cluster-sharingio-oci" {
  source = "./terraform/oci-talos-cluster"

  providers = {
    oci = oci
  }
  compartment_ocid = var.compartment_ocid
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
  fingerprint      = var.fingerprint
  region           = var.region

  talos_image_oci_bucket_url = local.talos_image_oci_bucket_url
  cluster_name               = "sharingio"
}
