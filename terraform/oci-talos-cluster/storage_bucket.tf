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

resource "oci_objectstorage_object" "talos_image_object" {
  #Required
  bucket    = oci_objectstorage_bucket.custom_image_bucket.name
  content   = data.http.talos_image_raw.response_body
  namespace = oci_objectstorage_bucket.custom_image_bucket.namespace
  object    = local.image_bucket_object
}
