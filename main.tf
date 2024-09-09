module "cluster-sharingio-oke" {
  source = "./terraform/oci-oke-cluster"

  providers = {
    oci = oci
  }

  compartment_ocid = var.compartment_ocid
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
  fingerprint      = var.fingerprint
}
