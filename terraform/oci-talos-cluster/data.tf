data "oci_identity_compartment" "this" {
  id = var.compartment_ocid
}

data "oci_identity_availability_domains" "availability_domains" {
  #Required
  compartment_id = var.tenancy_ocid
}

data "talos_image_factory_extensions_versions" "this" {
  # get the latest talos version
  talos_version = var.talos_version
  filters = {
    names = local.talos_extensions
  }
}

data "talos_image_factory_urls" "this" {
  talos_version = var.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "oracle"
  architecture  = local.architecture
}

data "talos_client_configuration" "talosconfig" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoints            = [for k, v in oci_core_instance.cp : v.public_ip]
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.kube_apiserver_domain}:6443"

  machine_type    = "controlplane"
  machine_secrets = talos_machine_secrets.machine_secrets.machine_secrets

  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version

  docs     = false
  examples = false

  config_patches = [
    <<-EOT
    machine:
       kubelet:
         extraArgs:
           cloud-provider: external
       install:
         disk: /dev/sda
         extraKernelArgs:
            - console=console=ttyS1,115200n8
            - talos.platform=oracle
         wipe: false
         image: ${local.talos_install_image}
       network:
         interfaces:
           - interface: lo
             addresses:
               - ${oci_load_balancer_load_balancer.cp_load_balancer.ip_address_details[0].ip_address}
           - interface: bond0
             vip:
               ip: ${oci_load_balancer_load_balancer.cp_load_balancer.ip_address_details[0].ip_address}
    EOT
    ,
    <<-EOT
    machine:
       time:
         servers:
           - 169.254.169.254
       certSANs:
         - ${var.kube_apiserver_domain}
         - ${oci_load_balancer_load_balancer.cp_load_balancer.ip_address_details[0].ip_address}
       kubelet:
         extraArgs:
           cloud-provider: external
       features:
         kubePrism:
           enabled: true
           port: 7445
    cluster:
       allowSchedulingOnMasters: true
       # The rest of this is for cilium
       #  https://www.talos.dev/v1.3/kubernetes-guides/network/deploying-cilium/
       externalCloudProvider:
         enabled: true
         manifests:
           - https://raw.githubusercontent.com/oracle/oci-cloud-controller-manager/${var.oracle_cloud_ccm_version}/manifests/provider-config-instance-principals-example.yaml
           - https://github.com/oracle/oci-cloud-controller-manager/releases/download/${var.oracle_cloud_ccm_version}/oci-cloud-controller-manager-rbac.yaml
           - https://github.com/oracle/oci-cloud-controller-manager/releases/download/${var.oracle_cloud_ccm_version}/oci-cloud-controller-manager.yaml
       controllerManager:
         extraArgs:
           cloud-provider: external
       apiServer:
         extraArgs:
           cloud-provider: external
           anonymous-auth: true
         certSANs:
           - ${var.kube_apiserver_domain}
           - ${oci_load_balancer_load_balancer.cp_load_balancer.ip_address_details[0].ip_address}
    EOT
  ]
}
