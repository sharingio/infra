resource "oci_core_volume" "worker" {
  for_each = { for idx, val in random_pet.worker : idx => val }
  #Required
  compartment_id = var.compartment_ocid

  #Optional
  autotune_policies {
    #Required
    autotune_type   = "PERFORMANCE_BASED"
    max_vpus_per_gb = 20
  }
  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[each.key % length(data.oci_identity_availability_domains.availability_domains.availability_domains)].name
  block_volume_replicas {
    #Required
    availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[each.key % length(data.oci_identity_availability_domains.availability_domains.availability_domains)].name
  }
  display_name                   = "${var.cluster_name}-${each.value.id}"
  freeform_tags                  = local.common_labels
  size_in_gbs                    = "100"
  block_volume_replicas_deletion = true
}

resource "oci_core_volume_attachment" "worker_volume_attachment" {
  for_each = { for idx, val in oci_core_instance.worker : idx => val }
  #Required
  attachment_type = local.instance_launch_network_type
  instance_id     = each.value.id
  volume_id       = [for idx, val in oci_core_volume.worker : val.display_name == each.value.display_name ? val.id : ""][0]
}
