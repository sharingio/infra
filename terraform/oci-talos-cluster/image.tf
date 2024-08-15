resource "oci_core_image" "talos_image" {
  #Required
  compartment_id = var.compartment_ocid

  #Optional
  display_name  = "Talos ${var.talos_version}"
  freeform_tags = local.common_labels
  launch_mode   = local.image_launch_mode

  image_source_details {
    source_type = "objectStorageUri"
    source_uri  = local.image_source_uri

    #Optional
    operating_system         = "Talos Linux"
    operating_system_version = var.talos_version
    source_image_type        = "QCOW2"
  }
}

data "oci_core_image_shapes" "image_shapes" {
  depends_on = [oci_core_shape_management.image_shape]
  #Required
  image_id = oci_core_image.talos_image.id
}

resource "oci_core_shape_management" "image_shape" {
  #Required
  compartment_id = var.compartment_ocid
  image_id       = oci_core_image.talos_image.id
  shape_name     = var.instance_shape
}
