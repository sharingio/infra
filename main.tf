module "cluster-sharingio-oci" {
  source = "./terraform/oci-talos-cluster"

  providers = {
    oci = oci
  }
  compartment_ocid = var.compartment_ocid
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
  fingerprint      = var.fingerprint
  region           = var.region

  # Image is auto-uploaded from Talos Image Factory if not specified
  # talos_image_oci_bucket_url = null  # uses default auto-upload
  cluster_name = "sharingio"
}
resource "local_file" "kubeconfig" {
  filename = "kubeconfig"
  content  = module.cluster-sharingio-oci.kubeconfig
}
data "oci_network_load_balancer_network_load_balancers" "nlbs" {
  #Required
  compartment_id = var.compartment_ocid
}
module "cluster-sharingio-oci-manifests" {
  source = "./terraform/manifests"

  # Reserved IPs for service assignment
  ingress_ip   = local.ingress_ipv4
  dns_ip       = local.dns_ipv4
  wg_ip        = local.wireguard_ipv4
  apiserver_ip = local.apiserver_ipv4

  acme_email_address     = local.acme_email_address
  rfc2136_nameserver     = var.rfc2136_nameserver
  rfc2136_tsig_keyname   = var.rfc2136_tsig_keyname
  rfc2136_tsig_key       = var.rfc2136_tsig_key
  rfc2136_tsig_algorithm = "HMACSHA256"
  domain                 = var.domain
  coder_version          = var.coder_version
  authentik_version      = var.authentik_version
  # for coder to directly authenticate via github
  coder_oauth2_github_client_id     = var.coder_oauth2_github_client_id
  coder_oauth2_github_client_secret = var.coder_oauth2_github_client_secret
  # for coder to create gh tokens for rw within workspaces
  coder_gitauth_0_client_id     = var.coder_gitauth_0_client_id
  coder_gitauth_0_client_secret = var.coder_gitauth_0_client_secret

  providers = {
    kubernetes = kubernetes.cluster-sharingio-oci
    random     = random
  }
}

data "github_repository" "this" {
  full_name = "${var.github_org}/${var.github_repository}"
}
resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}
resource "github_repository_deploy_key" "this" {
  title      = "Flux"
  repository = var.github_repository
  key        = tls_private_key.flux.public_key_openssh
  read_only  = "false"
}
resource "flux_bootstrap_git" "this" {
  depends_on = [github_repository_deploy_key.this, module.cluster-sharingio-oci-manifests]

  embedded_manifests = true
  path               = "clusters/cluster-sharingio-oci"
  components_extra   = ["image-reflector-controller", "image-automation-controller"]
}
