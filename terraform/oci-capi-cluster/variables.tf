variable "compartment_ocid" {
  sensitive = true
}
variable "tenancy_ocid" {
  sensitive = true
}
variable "user_ocid" {
  sensitive = true
}
variable "fingerprint" {
  sensitive = true
}
variable "private_key_path" {
  default   = "~/.oci/oci_main_terraform.pem"
  sensitive = true
}
variable "instance_availability_domain" {
  default = null
}
variable "region" {
  description = "the OCI region where resources will be created"
  type        = string
  default     = null
}
variable "cluster_name" {
  type    = string
  default = "cncfocicapi"
}
variable "cidr_blocks" {
  type    = set(string)
  default = ["10.0.0.0/16"]
}
variable "subnet_block" {
  type    = string
  default = "10.0.0.0/24"
}
variable "talos_version" {
  type    = string
  default = "v1.7.6"
}
variable "kubernetes_version" {
  type    = string
  default = "v1.30.3"
}
variable "instance_shape" {
  default = "VM.Standard.A1.Flex"
}
variable "oracle_cloud_ccm_version" {
  default = "v1.29.0"
}
variable "talos_ccm_version" {
  type    = string
  default = "v1.6.0"
}
variable "pod_subnet_block" {
  type    = string
  default = "10.32.0.0/12"
}
variable "service_subnet_block" {
  type    = string
  default = "10.200.0.0/22"
}
variable "node_subnet_block" {
  type    = string
  default = "192.168.0.0/16"
}