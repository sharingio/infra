resource "oci_identity_policy" "oci_ccm" {
  #Required
  name           = "${var.cluster_name}-oci-ccm"
  compartment_id = var.compartment_ocid # tenancy_ocid doesn't work
  description    = "Instance access"
  statements = [
    // LoadBalancer Services
    "Allow dynamic-group test to read instance-family in compartment ${data.oci_identity_compartment.this.name}",
    "Allow dynamic-group test to use virtual-network-family in compartment ${data.oci_identity_compartment.this.name}",
    "Allow dynamic-group test to manage load-balancers in compartment ${data.oci_identity_compartment.this.name}",
    // CSI
    "Allow dynamic-group test to manage volume-family in compartment ${data.oci_identity_compartment.this.name}",
  ]

  #Optional
  freeform_tags = local.common_labels
}
