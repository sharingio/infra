// TODO use instance pool?

resource "oci_core_instance" "cp" {
  count = 1
  #Required
  availability_domain = var.instance_availability_domain
  compartment_id      = var.compartment_ocid
  shape               = var.instance_shape
  shape_config {
    ocpus         = 8
    memory_in_gbs = "128"
  }

  #Optional
  display_name   = "${var.cluster_name}-control-plane"
  freeform_tags  = local.common_labels
  hostname_label = "${var.cluster_name}-control-plane"
  launch_options {
    #Optional
    network_type = local.image_launch_mode
  }
  metadata = {
    "user_data" = data.talos_machine_configuration.controlplane.machine_configuration
  }
  source_details {
    #Required
    source_id   = oci_core_image.talos_image.id
    source_type = "image"
  }
  preserve_boot_volume = false
}
