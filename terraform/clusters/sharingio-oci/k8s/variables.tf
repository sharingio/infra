# Variables for k8s configuration layer

# Cluster connection
variable "kubeconfig_path" {
  description = "Path to kubeconfig file (from infra/ layer or existing cluster)"
  type        = string
  default     = "../infra/kubeconfig"
}

# Cluster IPs (from infra/ output or manual for existing clusters)
variable "cluster_ips" {
  description = "Reserved IPs for services"
  type = object({
    ingress   = string
    dns       = string
    apiserver = string
    wireguard = string
  })
}

# Cluster identity
variable "domain" {
  type    = string
  default = "sharing.io"
}

variable "admin_email" {
  description = "Admin email for ACME and bootstrap accounts"
  type        = string
  default     = "letsencrypt@ii.coop"
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

# DNS (RFC 2136) for service records
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

# Application versions
variable "coder_version" {
  description = "Version of coder"
  type        = string
  default     = "v2.16.0"
}

variable "authentik_version" {
  description = "Version of authentik"
  type        = string
  default     = "2024.4.0"
}

# Coder GitHub OAuth
variable "coder_oauth2_github_client_id" {
  type    = string
  default = ""
}

variable "coder_oauth2_github_client_secret" {
  type      = string
  default   = ""
  sensitive = true
}

variable "coder_gitauth_0_client_id" {
  type    = string
  default = ""
}

variable "coder_gitauth_0_client_secret" {
  type      = string
  default   = ""
  sensitive = true
}

# Authentik GitHub OAuth
variable "authentik_github_oauth_app_id" {
  type    = string
  default = ""
}

variable "authentik_github_oauth_app_secret" {
  type      = string
  default   = ""
  sensitive = true
}
