locals {
  # TODO add a wait for correct address here or in the resource consuming it
  ingress_ipv4 = [for ipaddr in toset(
    [for nlb in data.oci_network_load_balancer_network_load_balancers.nlbs.network_load_balancer_collection[0].items :
    nlb if startswith(nlb.display_name, "ingress-nginx")][0].ip_addresses
  ) : ipaddr if ipaddr.is_public == true][0].ip_address

  rfc2136_algorithm  = "hmac-sha256"
  acme_email_address = "letsencrypt@ii.coop"
}
