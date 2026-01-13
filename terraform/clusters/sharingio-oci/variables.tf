# Variables for sharingio-oci cluster

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
  default = ""
}

# GitHub
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
  sensitive = true
}

# DNS (RFC 2136)
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

# Cluster identity
variable "domain" {
  type    = string
  default = "sharing.io"
}

variable "admin_email" {
  description = "Admin email for ACME certificates and bootstrap accounts"
  type        = string
  default     = "letsencrypt@ii.coop"
}

# Coder GitHub OAuth (direct authentication bypassing authentik)
variable "coder_oauth2_github_client_id" {
  description = "Authenticating Coder directly to GitHub"
  type        = string
  default     = ""
}

variable "coder_oauth2_github_client_secret" {
  description = "Authenticating Coder directly to GitHub"
  type        = string
  default     = ""
  sensitive   = true
}

# Coder GitHub tokens (for workspace git operations)
variable "coder_gitauth_0_client_id" {
  description = "Retrieving a RW token for git operations in workspaces"
  type        = string
  default     = ""
}

variable "coder_gitauth_0_client_secret" {
  description = "Retrieving a RW token for git operations in workspaces"
  type        = string
  default     = ""
  sensitive   = true
}

# Authentik GitHub OAuth
variable "authentik_github_oauth_app_id" {
  description = "GitHub OAuth app ID for Authentik"
  type        = string
  default     = ""
}

variable "authentik_github_oauth_app_secret" {
  description = "GitHub OAuth app secret for Authentik"
  type        = string
  default     = ""
  sensitive   = true
}

# Application versions
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

# Cloudflare (optional, for hybrid DNS setups)
variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS management"
  type        = string
  sensitive   = true
  default     = ""
}
