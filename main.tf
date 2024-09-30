locals {
  talos_image_oci_bucket_url = "https://axe608t7iscj.objectstorage.us-phoenix-1.oci.customer-oci.com/n/axe608t7iscj/b/talos/o/talos-v1.8.0-oracle-amd64.oci"
}
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

  talos_image_oci_bucket_url = local.talos_image_oci_bucket_url
  cluster_name               = "sharingio"
}
resource "local_file" "kubeconfig" {
  filename = "kubeconfig"
  content  = module.cluster-sharingio-oci.kubeconfig
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
  depends_on = [github_repository_deploy_key.this]

  embedded_manifests = true
  path               = "clusters/cluster-sharingio-oci"
  components_extra   = ["image-reflector-controller", "image-automation-controller"]
}
data "oci_network_load_balancer_network_load_balancers" "nlbs" {
  #Required
  compartment_id = var.compartment_ocid
}
