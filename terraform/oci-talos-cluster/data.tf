data "oci_identity_compartment" "this" {
  id = var.compartment_ocid
}

data "oci_identity_availability_domains" "availability_domains" {
  #Required
  compartment_id = var.tenancy_ocid
}

data "oci_core_image_shapes" "image_shapes" {
  depends_on = [oci_core_shape_management.image_shape]
  #Required
  image_id = oci_core_image.talos_image.id
}

data "talos_image_factory_extensions_versions" "this" {
  # get the latest talos version
  talos_version = var.talos_version
  filters = {
    names = var.talos_extensions
  }
}

data "talos_image_factory_urls" "this" {
  talos_version = var.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "oracle"
  architecture  = var.architecture
}

data "talos_client_configuration" "talosconfig" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoints            = [for k, v in oci_core_instance.controlplane : v.public_ip]
  nodes = concat(
    [for k, v in oci_core_instance.controlplane : v.public_ip],
    [for k, v in oci_core_instance.worker : v.private_ip]
  )
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
    yamlencode([
      {
        "op" : "replace",
        "path" : "/cluster/inlineManifests/2/contents",
        "value" : data.helm_template.cilium.manifest
      }
    ]),
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
          ],
          [for k, v in oci_core_instance.controlplane : v.public_ip]
        )
      }
      cluster = {
        apiServer = {
          certSANs = concat([
            var.kube_apiserver_domain,
            oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.ip_addresses[0].ip_address,
            ],
            [for k, v in oci_core_instance.controlplane : v.public_ip]
          )
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
    <<EOF
machine:
  nodeLabels:
    node-role.ii.nz/worker: ""
EOF
    ,
    var.worker_volume_enabled == true ? <<EOF
machine:
   disks:
     - device: /dev/sdb
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
        - destination: /opt/local-path-provisioner
          type: bind
          source: /opt/local-path-provisioner
          options:
          - bind
          - rshared
          - rw
EOF
    : null,
    yamlencode({
      machine = {
        certSANs = concat([
          var.kube_apiserver_domain,
          oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.ip_addresses[0].ip_address,
          ],
          [for k, v in oci_core_instance.controlplane : v.public_ip]
        )
      }
      cluster = {
        apiServer = {
          certSANs = concat([
            var.kube_apiserver_domain,
            oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.ip_addresses[0].ip_address,
            ],
            [for k, v in oci_core_instance.controlplane : v.public_ip]
          )
        }
      }
    }),
  ]
}

data "helm_template" "cilium" {
  name       = "cilium"
  namespace  = "kube-system"
  repository = "https://helm.cilium.io/"

  chart        = "cilium"
  version      = var.cilium_version
  kube_version = var.kubernetes_version

  set {
    name  = "ipam.mode"
    value = "kubernetes"
  }

  set {
    name  = "securityContext.capabilities.ciliumAgent"
    value = "{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
  }

  set {
    name  = "securityContext.capabilities.cleanCiliumState"
    value = "{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
  }

  set {
    name  = "cgroup.autoMount.enabled"
    value = "false"
  }

  set {
    name  = "cgroup.hostRoot"
    value = "/sys/fs/cgroup"
  }

  set {
    name  = "k8sServiceHost"
    value = "localhost"
  }

  set {
    name  = "k8sServicePort"
    value = "7445"
  }

  set {
    name  = "socketLB.hostNamespaceOnly"
    value = "true"
  }

  set {
    name  = "cni.exclusive"
    value = "false"
  }
}
