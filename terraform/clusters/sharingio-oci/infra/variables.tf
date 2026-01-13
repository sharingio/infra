# Variables for OCI + Talos infrastructure

# OCI Authentication
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
  default = "us-phoenix-1"
}

# Cluster identity
variable "cluster_name" {
  type    = string
  default = "sharingio"
}

variable "domain" {
  type    = string
  default = "sharing.io"
}

# DNS (RFC 2136) for node records
variable "rfc2136_nameserver" {
  type      = string
  sensitive = true
}

variable "rfc2136_port" {
  type    = number
  default = 53
}

variable "rfc2136_tsig_keyname" {
  type      = string
  sensitive = true
}

variable "rfc2136_tsig_key" {
  type      = string
  sensitive = true
}
