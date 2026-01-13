# Reserved Public IPs that survive cluster rebuilds
# These IPs are assigned to services via Cilium L2 announcements
#
# NOTE: Build machine DNS IP (MANUALLY MANAGED - NOT IN TERRAFORM):
#   IP: 161.153.15.215
#   OCID: ocid1.publicip.oc1.phx.amaaaaaadsqlhbiac54gry66rzcs52clldehtdv35srxsteu63i2ylt7b5rq
#   Purpose: Technitium DNS on build machine
#   Assigned to: Build machine secondary VNIC (10.0.0.81)

resource "oci_core_public_ip" "ingress" {
  compartment_id = var.compartment_ocid
  lifetime       = "RESERVED"
  display_name   = "${var.cluster_name}-ingress"

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_public_ip" "dns" {
  compartment_id = var.compartment_ocid
  lifetime       = "RESERVED"
  display_name   = "${var.cluster_name}-dns"

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_public_ip" "wireguard" {
  compartment_id = var.compartment_ocid
  lifetime       = "RESERVED"
  display_name   = "${var.cluster_name}-wireguard"

  lifecycle {
    prevent_destroy = true
  }
}
