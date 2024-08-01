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
  default = "bzBe:US-SANJOSE-1-AD-1"
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
variable "talos_version" {
  type    = string
  default = "v1.7.5"
}
variable "kubernetes_version" {
  type    = string
  default = "v1.30.0"
}
variable "instance_shape" {
  default = null
}
variable "oracle_cloud_ccm_version" {
  default = "v1.29.0"
}
