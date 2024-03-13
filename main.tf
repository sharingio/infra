module "cloudnative-coop" {
  source = "./terraform/equinix-metal-talos-cluster"

  cluster_name             = "cloudnative-coop"
  kube_apiserver_domain    = "${local.k8s_apiserver_subdomain}.cloudnative.coop"
  equinix_metal_project_id = var.equinix_metal_project_id
  equinix_metal_metro      = var.euqinix_metal_metro
  equinix_metal_auth_token = var.equinix_metal_auth_token
  equinix_metal_plan       = var.equinix_metal_plan
  talos_version            = local.talos_version
  kubernetes_version       = local.kubernetes_version
  ipxe_script_url          = local.ipxe_script_url
  controlplane_nodes       = 3
  talos_install_image      = local.talos_install_image

  providers = {
    talos   = talos
    helm    = helm
    equinix = equinix
  }
}
module "cloudnative-coop-record-apiserver-ip" {
  source = "./terraform/rfc2136-record-assign"

  zone      = "cloudnative.coop."
  name      = local.k8s_apiserver_subdomain
  addresses = [module.cloudnative-coop.cluster_apiserver_ip]

  providers = {
    dns = dns
  }

  depends_on = [module.cloudnative-coop]
}
module "cloudnative-coop-record-ingress-ip" {
  source = "./terraform/rfc2136-record-assign"

  zone      = "cloudnative.coop."
  name      = "*"
  addresses = [module.cloudnative-coop.cluster_ingress_ip]

  providers = {
    dns = dns
  }

  depends_on = [module.cloudnative-coop]
}
module "cloudnative-coop-record-dns-ip" {
  source = "./terraform/rfc2136-record-assign"

  zone      = "cloudnative.coop."
  name      = "dns"
  addresses = [module.cloudnative-coop.cluster_dns_ip]

  providers = {
    dns = dns
  }

  depends_on = [module.cloudnative-coop]
}
resource "powerdns_zone" "try" {
  name        = "try.cloudnative.coop."
  kind        = "Native"
  nameservers = ["ns1.cloudnative.coop.", "ns2.cloudnative.coop."]
}
resource "powerdns_record" "try-A" {
  zone       = "try.cloudnative.coop."
  name       = "try.cloudnative.coop."
  type       = "A"
  ttl        = 300
  records    = [module.cloudnative-coop.cluster_ingress_ip]
  depends_on = [powerdns_zone.try]
}
resource "powerdns_record" "try-WILDCARD" {
  zone       = "try.cloudnative.coop."
  name       = "*.try.cloudnative.coop."
  type       = "A"
  ttl        = 300
  records    = [module.cloudnative-coop.cluster_ingress_ip]
  depends_on = [powerdns_zone.try]
}
resource "powerdns_record" "wg-A" {
  # TUNNELD_WIREGUARD_ENDPOINT
  zone       = "cloudnative.coop."
  name       = "wg.cloudnative.coop."
  type       = "A"
  ttl        = 300
  records    = [module.cloudnative-coop.cluster_wireguard_ip]
  depends_on = [powerdns_zone.try]
}
resource "powerdns_zone" "coder" {
  name        = "coder.cloudnative.coop."
  kind        = "Native"
  nameservers = ["ns1.cloudnative.coop.", "ns2.cloudnative.coop."]
}
resource "powerdns_record" "coder-A" {
  zone       = "coder.cloudnative.coop."
  name       = "coder.cloudnative.coop."
  type       = "A"
  ttl        = 300
  records    = [module.cloudnative-coop.cluster_ingress_ip]
  depends_on = [powerdns_zone.coder]
}
resource "powerdns_record" "coder-WILDCARD" {
  zone       = "coder.cloudnative.coop."
  name       = "*.coder.cloudnative.coop."
  type       = "A"
  ttl        = 300
  records    = [module.cloudnative-coop.cluster_ingress_ip]
  depends_on = [powerdns_zone.coder]
}
module "cloudnative-coop-record-wireguard-ip" {
  source = "./terraform/rfc2136-record-assign"

  zone      = "cloudnative.coop."
  name      = "wireguard"
  addresses = [module.cloudnative-coop.cluster_wireguard_ip]

  providers = {
    dns = dns
  }

  depends_on = [module.cloudnative-coop]
}
resource "local_sensitive_file" "cloudnative-coop-kubeconfig" {
  content  = module.cloudnative-coop.kubeconfig.kubeconfig_raw
  filename = "./tmp/cloudnative-coop-kubeconfig"

  lifecycle {
    ignore_changes = all
  }
}
module "cloudnative-coop-manifests" {
  source = "./terraform/manifests"

  equinix_metal_project_id = var.equinix_metal_project_id
  equinix_metal_metro      = local.metro
  equinix_metal_auth_token = var.equinix_metal_auth_token
  ingress_ip               = module.cloudnative-coop.cluster_ingress_ip
  dns_ip                   = module.cloudnative-coop.cluster_dns_ip
  wg_ip                    = module.cloudnative-coop.cluster_wireguard_ip
  acme_email_address       = local.acme_email_address
  rfc2136_algorithm        = local.rfc2136_algorithm
  rfc2136_nameserver       = var.rfc2136_nameserver
  rfc2136_tsig_keyname     = var.rfc2136_tsig_keyname
  rfc2136_tsig_key         = var.rfc2136_tsig_key
  domain                   = "cloudnative.coop"
  pdns_host                = var.pdns_host
  pdns_api_key             = var.pdns_api_key
  # for coder to directly authenticate via github
  coder_oauth2_github_client_id     = var.coder_oauth2_github_client_id
  coder_oauth2_github_client_secret = var.coder_oauth2_github_client_secret
  # for coder to create gh tokens for rw within workspaces
  coder_gitauth_0_client_id     = var.coder_gitauth_0_client_id
  coder_gitauth_0_client_secret = var.coder_gitauth_0_client_secret
  providers = {
    kubernetes = kubernetes.cloudnative-coop
    random     = random
  }
  depends_on = [local_sensitive_file.cloudnative-coop-kubeconfig, module.cloudnative-coop]
}

module "cloudnative-coop-flux-bootstrap" {
  source = "./terraform/flux-bootstrap"

  github_org        = var.github_org
  github_repository = var.github_repository
  kubeconfig        = module.cloudnative-coop.kubeconfig.kubeconfig_raw

  providers = {
    github = github
    flux   = flux.cloudnative-coop
  }
  depends_on = [local_sensitive_file.cloudnative-coop-kubeconfig, module.cloudnative-coop-manifests]
}

module "cloudnative-coop-flux-github-webhook" {
  source = "./terraform/flux-github-webhook"

  repo = var.github_repository
  # repo   = "${var.github_org}/${var.github_repository}"
  domain = "cloudnative.coop"
  secret = module.cloudnative-coop-manifests.flux_receiver_token

  providers = {
    github     = github
    kubernetes = kubernetes.cloudnative-coop
  }

  depends_on = [local_sensitive_file.cloudnative-coop-kubeconfig, module.cloudnative-coop-manifests, module.cloudnative-coop-flux-bootstrap]
}

# module "cloudnative-coop-authentik-config" {
#   source                             = "./terraform/authentik-config"
#   github_oauth_app_id                = var.authentik_github_oauth_app_id
#   github_oauth_app_secret            = var.authentik_github_oauth_app_secret
#   authentik_coder_oidc_client_id     = module.cloudnative-coop-manifests.authentik_coder_oidc_client_id
#   authentik_coder_oidc_client_secret = module.cloudnative-coop-manifests.authentik_coder_oidc_client_secret
#   authentik_bootstrap_token          = module.cloudnative-coop-manifests.authentik_bootstrap_token
#   # repo = var.github_repository
#   # # repo   = "${var.github_org}/${var.github_repository}"
#   # domain = "cloudnative.coop"
#   # secret = module.cloudnative-coop-manifests.flux_receiver_token

#   providers = {
#     authentik  = authentik
#     flux       = flux
#     kubernetes = kubernetes.cloudnative-coop
#   }

#   depends_on = [module.cloudnative-coop-manifests]
# }
