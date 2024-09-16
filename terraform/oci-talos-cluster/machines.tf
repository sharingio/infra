resource "random_pet" "random" {
  count     = local.controlplane_instance_count
  length    = 2
  separator = "-"
}

resource "oci_core_instance" "cp" {
  for_each = { for idx, val in random_pet.random : idx => val }
  # count = 1
  #Required
  # choose the next availability domain which wasn't last
  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[each.key % length(data.oci_identity_availability_domains.availability_domains.availability_domains)].name
  compartment_id      = var.compartment_ocid
  shape               = var.instance_shape == null ? data.oci_core_image_shapes.image_shapes.image_shape_compatibilities[0].shape : var.instance_shape
  shape_config {
    ocpus         = local.controlplane_instance_ocpus
    memory_in_gbs = local.controlplane_instance_memory_in_gbs
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
  display_name  = "${var.cluster_name}-control-plane-${each.value.id}"
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

  lifecycle {
    create_before_destroy = "true"
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_instance_pool" "worker" {
  compartment_id            = var.compartment_ocid
  instance_configuration_id = oci_core_instance_configuration.worker.id
  size                      = local.worker_instance_count
  state                     = "RUNNING"
  display_name              = "${var.cluster_name}-worker"
  freeform_tags             = local.common_labels

  placement_configurations {
    availability_domain = var.instance_availability_domain == null ? data.oci_identity_availability_domains.availability_domains.availability_domains[0].name : var.instance_availability_domain
    primary_subnet_id   = oci_core_subnet.subnet_regional.id
  }
  placement_configurations {
    availability_domain = var.instance_availability_domain == null ? data.oci_identity_availability_domains.availability_domains.availability_domains[1].name : var.instance_availability_domain
    primary_subnet_id   = oci_core_subnet.subnet_regional.id
  }
  placement_configurations {
    availability_domain = var.instance_availability_domain == null ? data.oci_identity_availability_domains.availability_domains.availability_domains[2].name : var.instance_availability_domain
    primary_subnet_id   = oci_core_subnet.subnet_regional.id
  }

  lifecycle {
    ignore_changes = [
      state,
      defined_tags
    ]
  }
}

locals {
  worker_config_hash = substr(md5(base64encode(data.talos_machine_configuration.worker.machine_configuration)), 0, 7)
}

resource "oci_core_instance_configuration" "worker" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-worker-${local.worker_config_hash}"
  freeform_tags  = local.common_labels

  instance_details {
    instance_type = "compute"

    launch_details {
      compartment_id                      = var.compartment_ocid
      display_name                        = "${var.cluster_name}-worker-${local.worker_config_hash}"
      is_pv_encryption_in_transit_enabled = true
      preferred_maintenance_action        = "LIVE_MIGRATE"
      launch_mode                         = local.instance_launch_network_type

      shape = var.instance_shape == null ? data.oci_core_image_shapes.image_shapes.image_shape_compatibilities[0].shape : var.instance_shape
      shape_config {
        ocpus         = local.instance_ocpus
        memory_in_gbs = local.instance_memory_in_gbs
      }

      metadata = {
        user_data          = base64encode(data.talos_machine_configuration.worker.machine_configuration)
        worker_config_hash = local.worker_config_hash
      }

      source_details {
        source_type             = "image"
        image_id                = oci_core_image.talos_image.id
        boot_volume_size_in_gbs = "50"
      }
      create_vnic_details {
        display_name              = "${var.cluster_name}-worker"
        assign_private_dns_record = false
        assign_public_ip          = true
        nsg_ids                   = [oci_core_network_security_group.network_security_group.id]
        subnet_id                 = oci_core_subnet.subnet.id
        skip_source_dest_check    = true
      }

      agent_config {
        are_all_plugins_disabled = true
        is_management_disabled   = true
        is_monitoring_disabled   = true
      }
      launch_options {
        network_type = local.instance_launch_network_type
      }
      instance_options {
        are_legacy_imds_endpoints_disabled = true
      }
      availability_config {
        recovery_action = "RESTORE_INSTANCE"
      }
    }
  }

  lifecycle {
    create_before_destroy = "true"
    ignore_changes = [
      defined_tags
    ]
  }
}
