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
  talos_schematic        = talos_image_factory_schematic.this.id
  architecture           = "arm64"
  talos_disk_image_url   = data.talos_image_factory_urls.this.urls.disk_image
  talos_install_image    = data.talos_image_factory_urls.this.urls.installer
  image_launch_mode      = "PARAVIRTUALIZED"
  talos_install_disk     = data.talos_machine_disks.this.disks[0].name
  image_bucket_namespace = "custom_image"
  image_bucket_object    = "talos-${var.talos_version}.raw.xz"
}
