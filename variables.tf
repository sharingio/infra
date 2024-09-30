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
variable "region" {
  type    = string
  default = ""
}
variable "github_org" {
  type    = string
  default = "sharingio"
}
variable "github_repository" {
  type    = string
  default = "infra"
}
variable "github_token" {
  type      = string
  default   = "infra"
  sensitive = true
}
variable "rfc2136_nameserver" {
  type      = string
  sensitive = true
}
variable "rfc2136_tsig_keyname" {
  type      = string
  sensitive = true
}
variable "rfc2136_tsig_key" {
  type      = string
  sensitive = true
}
variable "pdns_host" {
  type      = string
  sensitive = true
}
variable "pdns_api_key" {
  type      = string
  sensitive = true
}
variable "domain" {
  type    = string
  default = "sharing.io"
}
