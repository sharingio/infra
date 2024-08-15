locals {
  talos_extensions = [
    "gvisor",
    "kata-containers",
    "iscsi-tools",
    "mdadm",
  ]
  common_labels = {
    "TalosCluster" = var.cluster_name
  }
  talos_schematic              = talos_image_factory_schematic.this.id
  architecture                 = "arm64"
  talos_disk_image_url         = data.talos_image_factory_urls.this.urls.disk_image
  talos_install_image          = data.talos_image_factory_urls.this.urls.installer
  image_launch_mode            = "PARAVIRTUALIZED"
  instance_launch_network_type = "PARAVIRTUALIZED"
  talos_install_disk           = "/dev/sda"
  image_bucket_namespace       = "custom_image"
  image_bucket_object          = "talos-${local.architecture}-${var.talos_version}.raw.xz"
  # image_source_uri = "https://axtwf1hkrwcy.objectstorage.us-sanjose-1.oci.customer-oci.com/n/axtwf1hkrwcy/b/talos/o/talos-v1.6.7-oracle-arm64.oci"
  # image_source_uri            = "https://axtwf1hkrwcy.objectstorage.us-sanjose-1.oci.customer-oci.com/n/axtwf1hkrwcy/b/talos/o/talos-v1.7.6-oracle-arm64.oci"
  image_source_uri            = "https://axtwf1hkrwcy.objectstorage.us-sanjose-1.oci.customer-oci.com/n/axtwf1hkrwcy/b/talos/o/talos-v1.7.6-oracle-arm64.oci"
  instance_ocpus              = 8
  instance_memory_in_gbs      = "128"
  instance_kernel_arg_console = "ttyAMA0"
}
