resource "oci_identity_user" "cluster_ccm_user" {
  #Required
  compartment_id = var.tenancy_ocid
  description    = "A user account to handle authenticate between the Oracle CCM and OCI"
  name           = "${var.cluster_name}-ccm-user"

  #Optional
  freeform_tags = local.common_labels
}
resource "tls_private_key" "ccm_user_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "oci_identity_api_key" "ccm_user_api_key" {
  #Required
  key_value = tls_private_key.ccm_user_key.private_key_pem
  user_id   = oci_identity_user.cluster_ccm_user.id
}
resource "oci_identity_policy" "oci_ccm" {
  #Required
  name           = "${var.cluster_name}-oci-ccm"
  compartment_id = var.compartment_ocid # tenancy_ocid doesn't work
  description    = "Instance access"
  statements = [
    // LoadBalancer Services
    "allow user ${oci_identity_user.cluster_ccm_user.name} to read instance-family in compartment ${data.oci_identity_compartment.this.name}",
    "allow user ${oci_identity_user.cluster_ccm_user.name} to use virtual-network-family in compartment ${data.oci_identity_compartment.this.name}",
    "allow user ${oci_identity_user.cluster_ccm_user.name} to manage load-balancers in compartment ${data.oci_identity_compartment.this.name}",
    // CSI
    "allow user ${oci_identity_user.cluster_ccm_user.name} to manage volume-family in compartment ${data.oci_identity_compartment.this.name}",
  ]

  #Optional
  freeform_tags = local.common_labels
}
