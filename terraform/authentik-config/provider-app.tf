
resource "authentik_application" "coder" {
  name               = "coder"
  slug               = "coder"
  group              = "ii"
  meta_description   = "Coder for Sharing"
  meta_icon          = "https://avatars.githubusercontent.com/u/95932066?s=200&v=4"
  meta_launch_url    = "https://coder.${var.domain}/api/v2/users/oidc/callback?redirect=%2F"
  open_in_new_tab    = false
  policy_engine_mode = "any"
  protocol_provider  = authentik_provider_oauth2.coder.id
}


data "authentik_scope_mapping" "coder" {
  # Search by name, by managed field or by scope_name
  # name    = "authentik default OAuth Mapping: Proxy outpost"
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-offline_access",
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-profile"
  ]
}

data "authentik_flow" "default-provider-authorization-implicit-consent" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default-authentication-flow" {
  slug = "default-authentication-flow"
}

resource "authentik_provider_oauth2" "coder" {
  name               = "coder"
  client_type        = "confidential" # OR public
  client_id          = var.authentik_coder_oidc_client_id
  client_secret      = var.authentik_coder_oidc_client_secret
  authorization_flow = data.authentik_flow.default-provider-authorization-implicit-consent.id
  # authorization_flow         = data.authentik_flow.default-authorization-flow.id
  authentication_flow = data.authentik_flow.default-authentication-flow.id
  # authentication_flow = authentik_flow.ii-authentication-flow.uuid
  # authorization_flow         = authentik_flow.ii-provider-authorization-implicent-consent.id
  access_code_validity       = "minutes=1"
  access_token_validity      = "minutes=10"
  refresh_token_validity     = "days=30"
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"
  sub_mode                   = "user_email"
  # jwks_sources               = [authentik_source_oauth.github.uuid] # JWTs issued by sources can authenticate on behalf
  property_mappings = data.authentik_scope_mapping.coder.ids
  # redirect_uris              = []
  # signing_key                = ""
}
