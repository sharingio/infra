locals {
  talos_image_object_name = "talos-${var.talos_version}-oracle-amd64.qcow2"
  talos_image_url = coalesce(
    var.talos_image_oci_bucket_url,
    "https://${var.oci_bucket_namespace}.objectstorage.${var.region}.oci.customer-oci.com/n/${var.oci_bucket_namespace}/b/${var.oci_bucket_name}/o/${local.talos_image_object_name}"
  )
}

# Upload Talos image to OCI bucket if not already present
resource "null_resource" "upload_talos_image" {
  count = var.talos_image_oci_bucket_url == null ? 1 : 0

  triggers = {
    talos_version = var.talos_version
    schematic_id  = talos_image_factory_schematic.this.id
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/upload-talos-image.sh ${talos_image_factory_schematic.this.id} ${var.talos_version} ${var.oci_bucket_name} ${var.oci_bucket_namespace} ${var.region}"
  }
}

resource "oci_core_image" "talos_image" {
  depends_on = [null_resource.upload_talos_image]

  #Required
  compartment_id = var.compartment_ocid

  #Optional
  display_name  = "Talos ${var.talos_version}"
  freeform_tags = local.common_labels
  launch_mode   = local.instance_mode

  image_source_details {
    source_type = "objectStorageUri"
    source_uri  = local.talos_image_url

    #Optional
    operating_system         = "Talos Linux"
    operating_system_version = var.talos_version
    source_image_type        = "QCOW2"
  }
}

resource "oci_core_shape_management" "image_shape" {
  #Required
  compartment_id = var.compartment_ocid
  image_id       = oci_core_image.talos_image.id
  shape_name     = var.instance_shape
}
