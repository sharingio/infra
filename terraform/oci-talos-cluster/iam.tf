resource "oci_identity_group" "this" {
  name           = var.cluster_name
  description    = "manage resources"
  compartment_id = var.tenancy_ocid
}

resource "oci_identity_dynamic_group" "instance_dynamic_group" {
  #Required
  compartment_id = var.compartment_ocid
  description    = "Instance access"
  matching_rule  = <<EOF
allow dynamic-group ${oci_identity_group.this.name} to read instance-family in compartment ${data.oci_identity_compartment.this.name}
allow dynamic-group ${oci_identity_group.this.name} to use virtual-network-family in compartment ${data.oci_identity_compartment.this.name}
allow dynamic-group ${oci_identity_group.this.name} to manage load-balancers in compartment ${data.oci_identity_compartment.this.name}
allow dynamic-group ${oci_identity_group.this.name} to manage volume-family in compartment ${data.oci_identity_compartment.this.name}
EOF
  name           = oci_identity_group.this.name

  #Optional
  freeform_tags = local.common_labels
}
