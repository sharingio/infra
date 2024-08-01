resource "oci_objectstorage_bucket" "custom_image_bucket" {
  #Required
  compartment_id = var.compartment_ocid
  name           = "${var.cluster_name}-custom-image-bucket"
  namespace      = local.image_bucket_namespace

  #Optional
  access_type   = "NoPublicAccess"
  auto_tiering  = "Disabled"
  freeform_tags = local.common_labels
  storage_tier  = "Standard"
  versioning    = "Disabled"
}
