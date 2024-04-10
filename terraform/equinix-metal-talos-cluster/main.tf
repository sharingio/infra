resource "random_pet" "random" {
  count  = var.controlplane_nodes
  length = 2
}

resource "equinix_metal_device" "cp" {
  for_each         = { for idx, val in random_pet.random : idx => val }
  hostname         = "${var.cluster_name}-${each.value.id}"
  plan             = var.equinix_metal_plan
  metro            = var.equinix_metal_metro
  operating_system = "custom_ipxe"
  billing_cycle    = "hourly"
  project_id       = var.equinix_metal_project_id
  ipxe_script_url  = var.ipxe_script_url
  always_pxe       = "false"
}

resource "equinix_metal_bgp_session" "cp_bgp" {
  for_each       = { for idx, val in equinix_metal_device.cp : idx => val }
  device_id      = each.value.id
  address_family = "ipv4"
}

resource "equinix_metal_reserved_ip_block" "cluster_apiserver_ip" {
  project_id = var.equinix_metal_project_id
  type       = "public_ipv4"
  metro      = var.equinix_metal_metro
  quantity   = 1
  tags       = ["eip-apiserver-${var.cluster_name}"]
}

resource "equinix_metal_reserved_ip_block" "cluster_ingress_ip" {
  project_id = var.equinix_metal_project_id
  type       = "public_ipv4"
  metro      = var.equinix_metal_metro
  quantity   = 1
  tags       = ["eip-ingress-${var.cluster_name}"]
}

resource "equinix_metal_reserved_ip_block" "cluster_dns_ip" {
  project_id = var.equinix_metal_project_id
  type       = "public_ipv4"
  metro      = var.equinix_metal_metro
  quantity   = 1
  tags       = ["eip-dns-${var.cluster_name}"]
}

resource "equinix_metal_reserved_ip_block" "cluster_wireguard_ip" {
  project_id = var.equinix_metal_project_id
  type       = "public_ipv4"
  metro      = var.equinix_metal_metro
  quantity   = 1
  tags       = ["eip-wireguard-${var.cluster_name}"]
}

resource "talos_machine_secrets" "machine_secrets" {
  talos_version = var.talos_version
}

# NOTE
#       anonymous-auth is set to true for the APIServer.
#       this must be removed after a future update to the Equinix Metal Cloud Provider controller.

resource "talos_machine_configuration_apply" "cp" {
  for_each                    = { for idx, val in equinix_metal_device.cp : idx => val }
  endpoint                    = each.value.network.0.address
  node                        = each.value.network.0.address
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  depends_on                  = [equinix_metal_device.cp, equinix_metal_bgp_session.cp_bgp]
  config_patches = [
    <<-EOT
    machine:
       disks:
         - device: ${var.longhorn_disk}
           partitions:
             - mountpoint: /var/lib/longhorn
       kubelet:
         extraMounts:
           - destination: /var/lib/longhorn
             type: bind
             source: /var/lib/longhorn
             options:
             - bind
             - rshared
             - rw
         nodeIP:
           validSubnets:
             - ${each.value.network.0.address}/32
         extraArgs:
           cloud-provider: external
       install:
         disk: ${var.talos_install_disk}
         extraKernelArgs:
            - console=ttyS1,115200n8
            - talos.platform=equinixMetal
         wipe: false
         image: ${var.talos_install_image}
       network:
         hostname: ${each.value.hostname}
         interfaces:
           - interface: lo
             addresses:
               - ${equinix_metal_reserved_ip_block.cluster_apiserver_ip.address}
           - interface: ens6f0
             dhcp: true
             vip:
               ip: ${equinix_metal_reserved_ip_block.cluster_ingress_ip.address}
               equinixMetal:
                 apiToken: ${var.equinix_metal_auth_token}
             routes:
               - network: ${data.equinix_metal_device_bgp_neighbors.bgp_neighbor[each.key].bgp_neighbors[0].peer_ips[0]}/32
                 gateway: ${[for k in each.value.network : k.address if k.public == false && k.family == 4][0]}
               - network: ${data.equinix_metal_device_bgp_neighbors.bgp_neighbor[each.key].bgp_neighbors[0].peer_ips[1]}/32
                 gateway: ${[for k in each.value.network : k.address if k.public == false && k.family == 4][0]}
           # - interface: bond0
           #   dhcp: true
           #   bond:
           #     deviceSelectors:
           #       - busPath: "00:*"
           #     mode: 802.3ad
           #     lacpRate: fast
           #     xmitHashPolicy: layer3+4
           #     miimon: 100
           #     updelay: 200
           #     downdelay: 200
           #   vip:
           #     ip: ${equinix_metal_reserved_ip_block.cluster_ingress_ip.address}
           #     equinixMetal:
           #       apiToken: ${var.equinix_metal_auth_token}
           #   routes:
           #     - network: ${data.equinix_metal_device_bgp_neighbors.bgp_neighbor[each.key].bgp_neighbors[0].peer_ips[0]}/32
           #       gateway: ${[for k in each.value.network : k.address if k.public == false && k.family == 4][0]}
           #     - network: ${data.equinix_metal_device_bgp_neighbors.bgp_neighbor[each.key].bgp_neighbors[0].peer_ips[1]}/32
           #       gateway: ${[for k in each.value.network : k.address if k.public == false && k.family == 4][0]}
    EOT
    ,
    <<-EOT
    machine:
       certSANs:
         - ${var.kube_apiserver_domain}
         - ${equinix_metal_reserved_ip_block.cluster_apiserver_ip.network}
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
           - https://github.com/equinix/cloud-provider-equinix-metal/releases/download/${var.equinix_metal_cloudprovider_controller_version}/deployment.yaml
       controllerManager:
         extraArgs:
           cloud-provider: external
       apiServer:
         extraArgs:
           cloud-provider: external
           anonymous-auth: true
         certSANs:
           - ${var.kube_apiserver_domain}
           - ${equinix_metal_reserved_ip_block.cluster_apiserver_ip.network}
       inlineManifests:
         - name: metal-cloud-config
           contents: |
             apiVersion: v1
             stringData:
               cloud-sa.json: |
                 {"apiKey":"${var.equinix_metal_auth_token}","projectID":"${var.equinix_metal_project_id}","metro":"${var.equinix_metal_metro}","eipTag":"eip-apiserver-${var.cluster_name}","eipHealthCheckUseHostIP":true,"loadBalancer":"metallb:///metallb-system?crdConfiguration=true"}
             kind: Secret
             metadata:
               name: metal-cloud-config
               namespace: kube-system
    EOT
  ]
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on = [
    talos_machine_configuration_apply.cp
  ]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoint             = [for k, v in equinix_metal_device.cp : v.network.0.address][0]
  node                 = [for k, v in equinix_metal_device.cp : v.network.0.address][0]
}
