# resource "kubernetes_namespace" "cert-manager" {
#   metadata {
#     name = "cert-manager"
#   }

#   lifecycle {
#     # prevent_destroy = true
#     ignore_changes = [
#       metadata["labels"],
#     ]
#   }
# }


resource "kubernetes_secret_v1" "rfc2136-dns-server" {
  metadata {
    name      = "rfc2136dnsserver"
    namespace = "flux-system"
  }

  data = {
    email      = var.acme_email_address
    nameserver = var.rfc2136_nameserver
    keyname    = var.rfc2136_tsig_keyname
    key        = var.rfc2136_tsig_key
    algorithm  = var.rfc2136_tsig_algorithm
    domain     = var.domain
  }
  depends_on = [
    kubernetes_namespace.flux-system
  ]
}

resource "kubernetes_secret_v1" "rfc2136-cert-manager" {
  metadata {
    name      = "rfc2136"
    namespace = "cert-manager"
  }

  data = {
    key = var.rfc2136_tsig_key
  }
  depends_on = [
    kubernetes_namespace.cert-manager
  ]
}

