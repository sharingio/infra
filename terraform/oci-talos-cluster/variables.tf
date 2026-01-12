variable "compartment_ocid" {
  type      = string
  sensitive = true
}
variable "tenancy_ocid" {
  type      = string
  sensitive = true
}
variable "user_ocid" {
  type      = string
  sensitive = true
}
variable "fingerprint" {
  type      = string
  sensitive = true
}
variable "private_key_path" {
  type      = string
  default   = "~/.oci/oci_main_terraform.pem"
  sensitive = true
}
variable "instance_availability_domain" {
  type    = string
  default = null
}
variable "region" {
  description = "the OCI region where resources will be created"
  type        = string
  default     = null
}
variable "cluster_name" {
  type    = string
  default = "cncfoci"
}
variable "kube_apiserver_domain" {
  type    = string
  default = "kube-cncfoci.sharing.io"
}
variable "cidr_blocks" {
  type    = set(string)
  default = ["10.0.0.0/16"]
}
variable "subnet_block" {
  type    = string
  default = "10.0.0.0/24"
}
variable "subnet_block_regional" {
  type    = string
  default = "10.0.10.0/24"
}
variable "talos_version" {
  type    = string
  default = "v1.12.1"
}
variable "kubernetes_version" {
  type    = string
  default = "v1.35.0"
}
variable "instance_shape" {
  type    = string
  default = "VM.Standard.E5.Flex"
}
variable "oracle_cloud_ccm_version" {
  type    = string
  default = "v1.29.0"
}
variable "talos_ccm_version" {
  type    = string
  default = "v1.11.0"
}
variable "cilium_version" {
  type    = string
  default = "1.18.5"
}
variable "pod_subnet_block" {
  type    = string
  default = "10.32.0.0/12"
}
variable "service_subnet_block" {
  type    = string
  default = "10.200.0.0/22"
}
variable "architecture" {
  type    = string
  default = "amd64"
}
variable "talos_extensions" {
  type = set(string)
  default = [
    "gvisor",
    "kata-containers",
    "iscsi-tools",
    "mdadm",
  ]
}
variable "controlplane_instance_count" {
  type    = number
  default = 3
}
variable "worker_instance_count" {
  type    = number
  default = 6
}
variable "talos_image_oci_bucket_url" {
  type        = string
  nullable    = true
  default     = null
  description = "URL to Talos image in OCI bucket. If null, image is auto-uploaded from Image Factory."
}
variable "oci_bucket_name" {
  type        = string
  default     = "talos"
  description = "OCI Object Storage bucket name for Talos images"
}
variable "oci_bucket_namespace" {
  type        = string
  default     = "axe608t7iscj"
  description = "OCI Object Storage namespace"
}
variable "controlplane_instance_ocpus" {
  type    = number
  default = 4
}
variable "controlplane_instance_memory_in_gbs" {
  type    = string
  default = "8"
}
variable "controlplane_boot_volume_size_in_gbs" {
  type    = string
  default = "250"
}
variable "worker_instance_ocpus" {
  type    = number
  default = 8
}
variable "worker_instance_memory_in_gbs" {
  type    = string
  default = "32"
}
variable "worker_volume_enabled" {
  type    = bool
  default = true
}
variable "worker_volume_size_in_gbs" {
  type    = string
  default = "500"
}
variable "worker_boot_volume_size_in_gbs" {
  type    = string
  default = "1024"
}
variable "domain" {
  description = "Domain for node hostnames (e.g., sharing.io)"
  type        = string
  default     = "sharing.io"
}
