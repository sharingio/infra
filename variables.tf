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
variable "domain" {
  type    = string
  default = "sharing.io"
}
variable "coder_oauth2_github_client_id" {
  description = "Authenticating Coder directly to github (bypassing authentik)"
  type        = string
  default     = ""
}
variable "coder_oauth2_github_client_secret" {
  description = "Authenticating Coder directly to github (bypassing authentik)"
  type        = string
  default     = ""
}
variable "coder_gitauth_0_client_id" {
  description = "Retrieving a RW token to save prs / commits etc in workspaces"
  type        = string
  default     = ""
}
variable "coder_gitauth_0_client_secret" {
  description = "Retrieving a RW token to save prs / commits etc in workspaces"
  type        = string
  default     = ""
}
variable "authentik_github_oauth_app_id" {
  description = "Github OAUTH app id"
  type        = string
  default     = ""
}
variable "authentik_github_oauth_app_secret" {
  description = "Github OAUTH app secrets"
  type        = string
  default     = ""
}
variable "coder_version" {
  description = "Version of coder from https://github.com/coder/coder/releases/"
  type        = string
  default     = "v2.16.0"
}
variable "authentik_version" {
  description = "Version of authentik from https://github.com/goauthentik/authentik/releases/"
  type        = string
  default     = "2024.4.0"
}
variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS management"
  type        = string
  sensitive   = true
  default     = ""
}
