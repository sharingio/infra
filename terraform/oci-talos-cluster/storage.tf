resource "oci_core_volume" "worker" {
  for_each = { for idx, val in oci_core_instance.worker : idx => val }
  #Required
  compartment_id = var.compartment_ocid

  #Optional
  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[each.key % length(data.oci_identity_availability_domains.availability_domains.availability_domains)].name
  display_name        = each.value.display_name
  freeform_tags       = local.common_labels
  size_in_gbs         = "500"

  lifecycle {
    create_before_destroy = "true"
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_volume_attachment" "worker_volume_attachment" {
  for_each = { for idx, val in oci_core_volume.worker : idx => val }
  #Required
  attachment_type = local.instance_launch_network_type
  instance_id     = [for val in oci_core_instance.worker : val if val.display_name == each.value.display_name][0].id
  volume_id       = each.value.id

  lifecycle {
    create_before_destroy = "true"
    ignore_changes = [
      defined_tags
    ]
  }
}
