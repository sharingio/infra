# sharingio-oci cluster - Talos on OCI with full self-hosted DNS
#
# This cluster:
# - Runs Talos Linux on Oracle Cloud Infrastructure
# - Uses self-hosted DNS (Technitium) for sharing.io zone
# - Hosts production workloads (Coder, Authentik, etc.)

module "cluster-sharingio-oci" {
  source = "../../modules/talos-cluster/oci"

  providers = {
    oci = oci
  }

  compartment_ocid = var.compartment_ocid
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
  fingerprint      = var.fingerprint
  region           = var.region

  cluster_name = "sharingio"

  # DNS nameservers for Talos nodes (separate from RFC 2136 update server)
  nameservers = [
    "161.153.15.215", # Technitium DNS (bootstrap, on build box)
    "8.8.8.8",        # Google DNS fallback
  ]
}

resource "local_file" "kubeconfig" {
  filename = "${path.module}/kubeconfig"
  content = yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name = "sharingio"
      cluster = {
        server                     = "https://k8s.${var.domain}:443"
        certificate-authority-data = module.cluster-sharingio-oci.kubeconfig_ca_certificate
      }
    }]
    contexts = [{
      name = "admin@sharingio"
      context = {
        cluster   = "sharingio"
        namespace = "default"
        user      = "admin@sharingio"
      }
    }]
    current-context = "admin@sharingio"
    users = [{
      name = "admin@sharingio"
      user = {
        client-certificate-data = module.cluster-sharingio-oci.kubeconfig_client_certificate
        client-key-data         = module.cluster-sharingio-oci.kubeconfig_client_key
      }
    }]
  })
  depends_on = [dns_a_record_set.k8s]
}

resource "local_file" "talosconfig" {
  filename = "${path.module}/talosconfig"
  content = yamlencode({
    context = "sharingio"
    contexts = {
      sharingio = {
        endpoints = [for name, node in module.cluster-sharingio-oci.controlplane_nodes : node.hostname]
        nodes = concat(
          [for name, node in module.cluster-sharingio-oci.controlplane_nodes : node.hostname],
          [for name, node in module.cluster-sharingio-oci.worker_nodes : node.hostname]
        )
        ca  = module.cluster-sharingio-oci.talos_client_ca
        crt = module.cluster-sharingio-oci.talos_client_crt
        key = module.cluster-sharingio-oci.talos_client_key
      }
    }
  })
  depends_on = [dns_a_record_set.controlplane, dns_a_record_set.worker]
}

data "oci_network_load_balancer_network_load_balancers" "nlbs" {
  compartment_id = var.compartment_ocid
}

module "cluster-sharingio-oci-manifests" {
  source = "../../modules/k8s-bootstrap"

  # Reserved IPs for service assignment
  ingress_ip   = local.ingress_ipv4
  dns_ip       = local.dns_ipv4
  wg_ip        = local.wireguard_ipv4
  apiserver_ip = local.apiserver_ipv4

  acme_email_address     = var.admin_email
  rfc2136_nameserver     = var.rfc2136_nameserver
  rfc2136_tsig_keyname   = var.rfc2136_tsig_keyname
  rfc2136_tsig_key       = var.rfc2136_tsig_key
  rfc2136_tsig_algorithm = "HMACSHA256"
  domain                 = var.domain
  coder_version          = var.coder_version
  authentik_version      = var.authentik_version

  # Coder GitHub OAuth (direct authentication)
  coder_oauth2_github_client_id     = var.coder_oauth2_github_client_id
  coder_oauth2_github_client_secret = var.coder_oauth2_github_client_secret

  # Coder GitHub tokens (for workspace git operations)
  coder_gitauth_0_client_id     = var.coder_gitauth_0_client_id
  coder_gitauth_0_client_secret = var.coder_gitauth_0_client_secret

  providers = {
    kubernetes = kubernetes.cluster-sharingio-oci
    random     = random
  }
}

# Flux GitOps bootstrap
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
  path               = "flux/clusters/cluster-sharingio-oci"
  components_extra   = ["image-reflector-controller", "image-automation-controller"]
}
