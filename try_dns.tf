resource "powerdns_zone" "try" {
  name        = "try.${var.domain}."
  kind        = "Native"
  nameservers = ["ns1.sharing.io.", "ns2.sharing.io."]
}
resource "powerdns_record" "try-A" {
  zone       = "try.${var.domain}."
  name       = "try.${var.domain}."
  type       = "A"
  ttl        = 300
  records    = [local.ingress_ipv4]
  depends_on = [powerdns_zone.try]
}
resource "powerdns_record" "try-WILDCARD" {
  zone       = "try.${var.domain}."
  name       = "*.try.${var.domain}."
  type       = "A"
  ttl        = 300
  records    = [local.ingress_ipv4]
  depends_on = [powerdns_zone.try]
}
