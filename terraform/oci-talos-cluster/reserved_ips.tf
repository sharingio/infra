# Reserved Public IPs that survive cluster rebuilds
# These IPs are assigned to services via Cilium L2 announcements

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
