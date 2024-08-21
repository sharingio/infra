resource "oci_identity_dynamic_group" "instance_dynamic_group" {
  #Required
  name           = "${var.cluster_name}-oci-ccm"
  compartment_id = var.tenancy_ocid
  description    = "Instance access"
  matching_rule  = <<EOF
ALL {instance.compartment.id = '${var.compartment_ocid}'}
EOF

  #Optional
  freeform_tags = local.common_labels
}
