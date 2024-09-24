data "oci_identity_compartment" "this" {
  id = var.compartment_ocid
}
data "oci_identity_tenancy" "this" {
  tenancy_id = var.tenancy_ocid
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
  endpoints            = [for k, v in oci_core_instance.controlplane : v.public_ip]
  nodes                = [for k, v in oci_core_instance.controlplane : v.public_ip]
}

locals {
  talos_base_configuration = <<-EOT
    machine:
       sysctls:
         user.max_user_namespaces: "11255"
       time:
         servers:
           - 169.254.169.254
       kubelet:
         extraArgs:
           cloud-provider: external
           rotate-server-certificates: "true"
       systemDiskEncryption:
         state:
           provider: luks2
           keys:
             - nodeID: {}
               slot: 0
         ephemeral:
           provider: luks2
           keys:
             - nodeID: {}
               slot: 0
           options:
             - no_read_workqueue
             - no_write_workqueue
       features:
         kubePrism:
           enabled: true
           port: 7445
       install:
         disk: ${local.talos_install_disk}
         extraKernelArgs:
            - console=console=${local.instance_kernel_arg_console}
            - talos.platform=oracle
         wipe: false
         image: ${local.talos_install_image}
    cluster:
       discovery:
         enabled: true
       network:
         podSubnets:
           - ${var.pod_subnet_block}
         serviceSubnets:
           - ${var.service_subnet_block}
       allowSchedulingOnMasters: false
       externalCloudProvider:
         enabled: true
         manifests:
           - https://raw.githubusercontent.com/siderolabs/talos-cloud-controller-manager/${var.talos_ccm_version}/docs/deploy/cloud-controller-manager.yml
           - https://github.com/oracle/oci-cloud-controller-manager/releases/download/${var.oracle_cloud_ccm_version}/oci-cloud-controller-manager-rbac.yaml
           - https://github.com/oracle/oci-cloud-controller-manager/releases/download/${var.oracle_cloud_ccm_version}/oci-cloud-controller-manager.yaml
       controllerManager:
         extraArgs:
           cloud-provider: external
       apiServer:
         extraArgs:
           cloud-provider: external
           anonymous-auth: true
       inlineManifests:
         - name: oci-cloud-controller-manager
           contents: |
             apiVersion: v1
             data:
               cloud-provider.yaml: ${base64encode(local.oci_cloud_provider_config)}
               config.ini: ${base64encode(local.oci_config_ini)}
             kind: Secret
             metadata:
               name: oci-cloud-controller-manager
               namespace: kube-system
         - name: oci-volume-provisioner
           contents: |
             apiVersion: v1
             data:
               config.yaml: ${base64encode(local.oci_cloud_provider_config)}
               config.ini: ${base64encode(local.oci_config_ini)}
             kind: Secret
             metadata:
               name: oci-volume-provisioner
               namespace: kube-system
    EOT
}

data "talos_machine_configuration" "controlplane" {
  cluster_name = var.cluster_name
  # cluster_endpoint = "https://${var.kube_apiserver_domain}:6443"
  cluster_endpoint = "https://${oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.ip_addresses[0].ip_address}:6443"

  machine_type    = "controlplane"
  machine_secrets = talos_machine_secrets.machine_secrets.machine_secrets

  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version

  docs     = false
  examples = false

  config_patches = [
    local.talos_base_configuration,
    <<-EOT
    machine:
      features:
        kubernetesTalosAPIAccess:
          enabled: true
          allowedRoles:
            - os:reader
          allowedKubernetesNamespaces:
            - kube-system
    EOT
    ,
    yamlencode({
      machine = {
        certSANs = concat([
          var.kube_apiserver_domain,
          oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.ip_addresses[0].ip_address,
        ], [for k, v in oci_core_instance.controlplane : v.public_ip], [for k, v in oci_core_instance.worker : v.public_ip])
      }
      cluster = {
        apiServer = {
          certSANs = concat([
            var.kube_apiserver_domain,
            oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.ip_addresses[0].ip_address,
          ], [for k, v in oci_core_instance.controlplane : v.public_ip], [for k, v in oci_core_instance.worker : v.public_ip])
        }
      }
    }),
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name = var.cluster_name
  # cluster_endpoint = "https://${var.kube_apiserver_domain}:6443"
  cluster_endpoint = "https://${oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.ip_addresses[0].ip_address}:6443"

  machine_type    = "worker"
  machine_secrets = talos_machine_secrets.machine_secrets.machine_secrets

  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version

  docs     = false
  examples = false

  config_patches = [
    local.talos_base_configuration,
    yamlencode({
      machine = {
        certSANs = concat([
          var.kube_apiserver_domain,
          oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.ip_addresses[0].ip_address,
        ], [for k, v in oci_core_instance.controlplane : v.public_ip])
      }
      cluster = {
        apiServer = {
          certSANs = concat([
            var.kube_apiserver_domain,
            oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.ip_addresses[0].ip_address,
          ], [for k, v in oci_core_instance.controlplane : v.public_ip])
        }
      }
    }),
  ]
}
