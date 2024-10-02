resource "powerdns_zone" "coder" {
  name        = "coder.${var.domain}."
  kind        = "Native"
  nameservers = ["ns1.sharing.io.", "ns2.sharing.io."]
}
resource "powerdns_record" "coder-A" {
  zone       = "coder.${var.domain}."
  name       = "coder.${var.domain}."
  type       = "A"
  ttl        = 300
  records    = [local.ingress_ipv4]
  depends_on = [powerdns_zone.coder]
}
resource "powerdns_record" "coder-WILDCARD" {
  zone       = "coder.${var.domain}."
  name       = "*.coder.${var.domain}."
  type       = "A"
  ttl        = 300
  records    = [local.ingress_ipv4]
  depends_on = [powerdns_zone.coder]
}
resource "powerdns_record" "WILDCARD" {
  zone       = "${var.domain}."
  name       = "*.${var.domain}."
  type       = "A"
  ttl        = 300
  records    = [local.ingress_ipv4]
  depends_on = [powerdns_zone.coder]
}
