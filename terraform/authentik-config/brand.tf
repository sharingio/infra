resource "authentik_brand" "ii" {
  domain              = var.domain
  default             = false
  branding_title      = "and ${var.domain}"
  branding_logo       = "https://ii.nz/assets/ii-fresh.png"
  branding_favicon    = "/static/dist/assets/icons/icon.png" # We should locate an old favicon
  flow_authentication = resource.authentik_flow.ii-authentication-flow.uuid
  flow_invalidation   = ""
  flow_user_settings  = ""
  attributes          = <<-EOT
  {
     "branding" : "ii"
  }
  EOT
  # web_certificate     = ""
  # flow_device_code    = ""
  # flow_recovery       = ""
  # flow_unenrollment   = ""
}
