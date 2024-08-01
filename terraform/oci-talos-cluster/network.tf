resource "oci_core_vcn" "vcn" {
  #Required
  compartment_id = var.compartment_ocid

  #Optional
  cidr_blocks   = var.cidr_blocks
  display_name  = "${var.cluster_name}-vcn"
  freeform_tags = local.common_labels

  # TODO ipv6
}
resource "oci_core_subnet" "subnet" {
  #Required
  cidr_block     = var.subnet_block
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id

  #Optional
  display_name  = "${var.cluster_name}-subnet"
  freeform_tags = local.common_labels
}
resource "oci_core_route_table" "route_table" {
  #Required
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id

  #Optional
  display_name  = "${var.cluster_name}-route-table"
  freeform_tags = local.common_labels
  route_rules {
    #Required
    network_entity_id = oci_core_internet_gateway.internet_gateway.id

    #Optional
    destination = "0.0.0.0/0"
  }
}
resource "oci_core_internet_gateway" "internet_gateway" {
  #Required
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id

  #Optional
  enabled       = true
  display_name  = "${var.cluster_name}-internet-gateway"
  freeform_tags = local.common_labels
}

# TODO security-list?

resource "oci_load_balancer_load_balancer" "cp_load_balancer" {
  #Required
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-cp-load-balancer"
  shape          = "flexible"
  shape_details {
    maximum_bandwidth_in_mbps = "1500"
    minimum_bandwidth_in_mbps = "150"
  }
  subnet_ids = [oci_core_subnet.subnet.id]

  #Optional
  freeform_tags = local.common_labels
  is_private    = false
  # TODO where is this option? --is-preserve-source-destination false
}
resource "oci_load_balancer_backend_set" "talos_backend_set" {
  #Required
  health_checker {
    #Required
    protocol = "TCP"
    #Optional
    interval_ms = 10000
    port        = 50000
  }
  load_balancer_id = oci_load_balancer_load_balancer.cp_load_balancer.id
  name             = "${var.cluster_name}-talos"
  policy           = "LEAST_CONNECTIONS"
  # TODO where is this option? --is-preserve-source false
}
resource "oci_load_balancer_listener" "talos_listener" {
  #Required
  default_backend_set_name = oci_load_balancer_backend_set.talos_backend_set.name
  load_balancer_id         = oci_load_balancer_load_balancer.cp_load_balancer.id
  name                     = "${var.cluster_name}-talos"
  port                     = 50000
  protocol                 = "TCP"
}
resource "oci_load_balancer_backend_set" "controlplane_backend_set" {
  #Required
  health_checker {
    #Required
    protocol = "HTTP"
    #Optional
    interval_ms = 10000
    port        = 6443
    return_code = 401
    url_path    = "/readyz"
  }
  load_balancer_id = oci_load_balancer_load_balancer.cp_load_balancer.id
  name             = "${var.cluster_name}-controlplane"
  policy           = "LEAST_CONNECTIONS"
  # TODO where is this option? --is-preserve-source false
}
resource "oci_load_balancer_listener" "controlplane_listener" {
  #Required
  default_backend_set_name = oci_load_balancer_backend_set.talos_backend_set.name
  load_balancer_id         = oci_load_balancer_load_balancer.cp_load_balancer.id
  name                     = "${var.cluster_name}-controlplane"
  port                     = 6443
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_backend" "talos_backend" {
  for_each = { for idx, val in oci_core_instance.cp : idx => val }
  #Required
  backend_set_name         = "talos"
  network_load_balancer_id = oci_load_balancer_load_balancer.cp_load_balancer.id
  port                     = 50000

  #Optional
  target_id = oci_core_instance.cp[each.key].id
}

resource "oci_network_load_balancer_backend" "controlplane_backend" {
  for_each = { for idx, val in oci_core_instance.cp : idx => val }
  #Required
  backend_set_name         = "controlplane"
  network_load_balancer_id = oci_load_balancer_load_balancer.cp_load_balancer.id
  port                     = 6443

  #Optional
  target_id = oci_core_instance.cp[each.key].id
}
