locals {
  # NOTE ipxe_script_url must be not contain extensions and must contain the following kernel args
  #   console=ttyS1,115200n8  talos.platform=equinixMetal
  ipxe_script_url = "https://pxe.factory.talos.dev/pxe/b5b2a4d2bd7add4eff1649fd7e580b61f376313aba7e5e3227bae12f45a0748b/v1.7.0-beta.0/metal-amd64"
  # NOTE install image must contain the following kernel args
  #   console=ttyS1,115200n8  talos.platform=equinixMetal
  #   It also needs gvisor, iscsi-tools, and mdadm extensions
  talos_install_image     = "factory.talos.dev/installer/25889b382ca7647e59d2a22d4cbb535e30d224f751b7e1d6ac677fb96fa1002d:v1.7.0-beta.0"
  talos_version           = "v1.7.0-beta"
  kubernetes_version      = "v1.29.2"
  k8s_apiserver_subdomain = "k8s"
}
