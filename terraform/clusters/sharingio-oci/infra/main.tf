# sharingio-oci infrastructure - OCI + Talos
#
# This layer provisions:
# - OCI VMs, networking, reserved IPs
# - Talos Linux configuration
# - Node DNS records
#
# Outputs kubeconfig and IPs for the k8s/ layer

module "cluster" {
  source = "../../../modules/talos-cluster/oci"

  providers = {
    oci = oci
  }

  compartment_ocid = var.compartment_ocid
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
  fingerprint      = var.fingerprint
  region           = var.region

  cluster_name = var.cluster_name

  # DNS nameservers for Talos nodes
  nameservers = [
    "161.153.15.215", # Technitium DNS (bootstrap)
    "8.8.8.8",        # Google DNS fallback
  ]
}

# Generate kubeconfig file for k8s/ layer
resource "local_file" "kubeconfig" {
  filename = "${path.module}/kubeconfig"
  content = yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name = var.cluster_name
      cluster = {
        server                     = "https://k8s.${var.domain}:443"
        certificate-authority-data = module.cluster.kubeconfig_ca_certificate
      }
    }]
    contexts = [{
      name = "admin@${var.cluster_name}"
      context = {
        cluster   = var.cluster_name
        namespace = "default"
        user      = "admin@${var.cluster_name}"
      }
    }]
    current-context = "admin@${var.cluster_name}"
    users = [{
      name = "admin@${var.cluster_name}"
      user = {
        client-certificate-data = module.cluster.kubeconfig_client_certificate
        client-key-data         = module.cluster.kubeconfig_client_key
      }
    }]
  })
  depends_on = [dns_a_record_set.k8s]
}

# Generate talosconfig file
resource "local_file" "talosconfig" {
  filename = "${path.module}/talosconfig"
  content = yamlencode({
    context = var.cluster_name
    contexts = {
      (var.cluster_name) = {
        endpoints = [for name, node in module.cluster.controlplane_nodes : node.hostname]
        nodes = concat(
          [for name, node in module.cluster.controlplane_nodes : node.hostname],
          [for name, node in module.cluster.worker_nodes : node.hostname]
        )
        ca  = module.cluster.talos_client_ca
        crt = module.cluster.talos_client_crt
        key = module.cluster.talos_client_key
      }
    }
  })
  depends_on = [dns_a_record_set.controlplane, dns_a_record_set.worker]
}

# OCI data for debugging
data "oci_network_load_balancer_network_load_balancers" "nlbs" {
  compartment_id = var.compartment_ocid
}
