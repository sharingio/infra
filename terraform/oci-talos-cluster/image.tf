data "http" "talos_image_raw" {
  url = local.talos_disk_image_url
}

resource "oci_core_image" "talos_image" {
  #Required
  compartment_id = var.compartment_ocid

  #Optional
  display_name  = "Talos ${var.talos_version}"
  launch_mode   = local.image_launch_mode
  freeform_tags = local.common_labels

  image_source_details {
    source_type = "objectStorageUri"
    source_uri  = oci_objectstorage_object.talos_image_object.source

    #Optional
    operating_system         = "Talos Linux"
    operating_system_version = var.talos_version
    source_image_type        = "QCOW2"
  }
}
