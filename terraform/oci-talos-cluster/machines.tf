// TODO use instance pool?

resource "oci_core_instance" "cp" {
  depends_on = [data.talos_machine_configuration.controlplane]

  count = 1
  #Required
  availability_domain = var.instance_availability_domain == null ? data.oci_identity_availability_domains.availability_domains.availability_domains[0].name : var.instance_availability_domain
  compartment_id      = var.compartment_ocid
  shape               = var.instance_shape == null ? data.oci_core_image_shapes.image_shapes.image_shape_compatibilities[0].shape : var.instance_shape
  shape_config {
    ocpus         = local.instance_ocpus
    memory_in_gbs = local.instance_memory_in_gbs
  }

  metadata = {
    user_data = base64encode(data.talos_machine_configuration.controlplane.machine_configuration)
  }

  create_vnic_details {
    assign_public_ip = true
    subnet_id        = oci_core_subnet.subnet.id
    nsg_ids          = [oci_core_network_security_group.network_security_group.id]
  }
  agent_config {
    are_all_plugins_disabled = true
    is_management_disabled   = true
    is_monitoring_disabled   = true
  }
  availability_config {
    is_live_migration_preferred = true
    recovery_action             = "RESTORE_INSTANCE"
  }
  #Optional
  display_name  = "${var.cluster_name}-control-plane"
  freeform_tags = local.common_labels
  launch_options {
    #Optional
    network_type            = local.instance_launch_network_type
    remote_data_volume_type = local.instance_launch_network_type
    boot_volume_type        = local.instance_launch_network_type
    firmware                = "UEFI_64"
  }
  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }
  source_details {
    #Required
    source_type             = "image"
    source_id               = oci_core_image.talos_image.id
    boot_volume_size_in_gbs = "50"
  }
  preserve_boot_volume = false
}
