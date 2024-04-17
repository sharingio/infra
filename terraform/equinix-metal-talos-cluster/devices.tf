locals {
  talos_schematic      = jsondecode(data.http.talos_schematic.response_body).id
  talos_latest_version = element(jsondecode(data.http.talos_versions.response_body), length(jsondecode(data.http.talos_versions.response_body)) - 1)
  ipxe_script_url      = "https://pxe.factory.talos.dev/pxe/${local.talos_schematic}/${var.talos_version}/equinixMetal-amd64"
  talos_install_image  = "factory.talos.dev/installer/${local.talos_schematic}:${var.talos_version}"
  # ipxe_script_url      = "https://pxe.factory.talos.dev/pxe/${local.talos_schematic}/${talos_latest_version}/equinixMetal-amd64"
  # talos_install_image  = "factory.talos.dev/installer/${local.talos_schematic}:${local.talos_latest_version}"
}


# https://github.com/siderolabs/image-factory?tab=readme-ov-file#get-versions

data "http" "talos_versions" {
  url = "https://factory.talos.dev/versions"
  request_headers = {
    Accept = "application/json"
  }
}

# https://github.com/siderolabs/image-factory?tab=readme-ov-file#http-frontend-api

data "http" "talos_schematic" {
  url    = "https://factory.talos.dev/schematics"
  method = "POST"
  request_headers = {
    Accept       = "application/json"
    Content-type = "text/x-yaml"
  }
  request_body = <<-EOT
    customization:
        systemExtensions:
            officialExtensions:
                - siderolabs/gvisor
                - siderolabs/iscsi-tools
                - siderolabs/mdadm
   EOT
}

resource "random_pet" "random" {
  count  = var.controlplane_nodes
  length = 2
}

resource "equinix_metal_device" "cp" {
  for_each = { for idx, val in random_pet.random : idx => val }
  # hostname = "${var.cluster_name}-${each.value.id}"
  hostname         = "${each.value.id}.${var.domain}"
  plan             = var.equinix_metal_plan
  metro            = var.equinix_metal_metro
  operating_system = "custom_ipxe"
  billing_cycle    = "hourly"
  project_id       = var.equinix_metal_project_id
  # https://github.com/siderolabs/image-factory?tab=readme-ov-file#get-pxeschematicversionpath
  ipxe_script_url = local.ipxe_script_url
  always_pxe      = "false"
}

resource "equinix_metal_bgp_session" "cp_bgp" {
  for_each       = { for idx, val in equinix_metal_device.cp : idx => val }
  device_id      = each.value.id
  address_family = "ipv4"
}

module "dns-record-node-ip" {
  for_each = { for idx, val in equinix_metal_device.cp : idx => val }
  source   = "../rfc2136-record-assign"

  zone      = "${var.domain}."
  name      = element(split(".", each.value.hostname), 0)
  addresses = [each.value.access_public_ipv4]

  providers = {
    dns = dns
  }
}
