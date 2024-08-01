resource "talos_machine_secrets" "machine_secrets" {
  talos_version = var.talos_version
}

resource "talos_machine_bootstrap" "bootstrap" {
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoint             = [for k, v in oci_core_instance.cp : v.public_ip][0]
  node                 = [for k, v in oci_core_instance.cp : v.public_ip][0]
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
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
  endpoint             = [for k, v in oci_core_instance.cp : v.public_ip][0]
  node                 = [for k, v in oci_core_instance.cp : v.public_ip][0]
}

resource "talos_machine_configuration_apply" "cp" {
  for_each                    = { for idx, val in oci_core_instance.cp : idx => val }
  endpoint                    = each.value.public_ip
  node                        = each.value.public_ip
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
}
