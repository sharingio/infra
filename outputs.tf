output "cluster-sharingio-oke-kubeconfig" {
  value     = module.cluster-sharingio-oke.kubeconfig
  sensitive = true
}
