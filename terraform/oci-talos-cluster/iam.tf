resource "oci_identity_dynamic_group" "oci-ccm" {
  #Required
  name           = "${var.cluster_name}-oci-ccm"
  compartment_id = var.tenancy_ocid # tenancy_ocid, compartment_ocid and domain_ocid doesn't work
  description    = "Instance access"
  matching_rule  = <<EOF
ALL {instance.compartment.id = '${var.compartment_ocid}'}
EOF

  #Optional
  freeform_tags = local.common_labels
}

resource "oci_identity_policy" "oci-ccm" {
  #Required
  name           = "${var.cluster_name}-oci-ccm"
  compartment_id = var.compartment_ocid # tenancy_ocid doesn't work
  description    = "Instance access"
  statements = [
    // LoadBalancer Services
    "allow dynamic-group ${oci_identity_dynamic_group.oci-ccm.name} to read instance-family in compartment ${data.oci_identity_compartment.this.name}",
    "allow dynamic-group ${oci_identity_dynamic_group.oci-ccm.name} to use virtual-network-family in compartment ${data.oci_identity_compartment.this.name}",
    "allow dynamic-group ${oci_identity_dynamic_group.oci-ccm.name} to manage load-balancers in compartment ${data.oci_identity_compartment.this.name}",

    // CSI
    "allow dynamic-group ${oci_identity_dynamic_group.oci-ccm.name} to read instance-family in compartment ${data.oci_identity_compartment.this.name}",
    "allow dynamic-group ${oci_identity_dynamic_group.oci-ccm.name} to use virtual-network-family in compartment ${data.oci_identity_compartment.this.name}",
    "allow dynamic-group ${oci_identity_dynamic_group.oci-ccm.name} to manage volume-family in compartment ${data.oci_identity_compartment.this.name}",
  ]

  #Optional
  freeform_tags = local.common_labels
}
