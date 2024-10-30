resource "talos_machine_secrets" "machine_secrets" {
  talos_version = var.talos_version
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info[*].name
        }
      }
    }
  )
}

resource "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on = [
    talos_machine_bootstrap.bootstrap
  ]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoint             = oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.ip_addresses[0].ip_address
  node                 = oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.ip_addresses[0].ip_address
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each                    = { for idx, val in oci_core_instance.controlplane : idx => val }
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = each.value.public_ip

  config_patches = [
    yamlencode({
      machine = {
        kubelet = {
          extraArgs = {
            "provider-id" = each.value.id
          }
        }
      }
    })
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  for_each                    = { for idx, val in oci_core_instance.worker : idx => val }
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  endpoint                    = [for k, v in oci_core_instance.controlplane : v.public_ip][0]
  node                        = each.value.private_ip

  config_patches = [
    yamlencode({
      machine = {
        kubelet = {
          extraArgs = {
            "provider-id" = each.value.id
          }
        }
        files = [
          {
            content = <<EOF
[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    device_ownership_from_security_context = true
EOF
            path = "/etc/cri/conf.d/20-customization.part"
            op = "create"
          }
        ]
      }
    }),
    yamlencode({
      machine = {
        network = {
          interfaces = [
            {
              interface = "br0"
              addresses = ["192.168.0.0/16"]
              bridge = {
                stp = {
                  enabled = true
                }
                interfaces = ["br0"]
              }
              routes = [
                {
                  network = "0.0.0.0/0"
                  gateway = "192.168.0.1"
                  metric = 1024
                }
              ]
            }
          ]
        }
      }
    })
  ]

  depends_on = [oci_core_volume_attachment.worker_volume_attachment, talos_machine_configuration_apply.controlplane]
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoint             = [for k, v in oci_core_instance.controlplane : v.public_ip][0]
  node                 = [for k, v in oci_core_instance.controlplane : v.public_ip][0]

  lifecycle {
    ignore_changes = all
  }
}
