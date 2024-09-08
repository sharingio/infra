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
