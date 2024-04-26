# I did try to create our own ii-source-enrollment-flow
# but I got errors and tracebacks. Loop back another time
# Just use the default one for now. It works.

data "authentik_flow" "default-source-enrollment" {
  slug = "default-source-enrollment"
}
resource "authentik_flow" "ii-source-enrollment-flow" {
  name               = "Welcome to ii! Please select a username."
  title              = "It's a great day to choose a user"
  slug               = "ii-source-enrollment-flow"
  designation        = "enrollment"
  authentication     = "none"
  compatibility_mode = true
  denied_action      = "message_continue"
  policy_engine_mode = "any"
  layout             = "stacked"
  background         = "/static/dist/assets/images/flow_background.jpg"
}

resource "authentik_flow" "ii-enrollment-flow" {
  name               = "Welcome to ii! Please select a username."
  title              = "It's a great day to choose a user"
  slug               = "ii-enrollment-flow"
  designation        = "enrollment"
  authentication     = "none"
  compatibility_mode = true
  denied_action      = "message_continue"
  policy_engine_mode = "any"
  layout             = "stacked"
  background         = "/static/dist/assets/images/flow_background.jpg"
}


resource "authentik_stage_prompt_field" "username" {
  name      = "ii username" # Unique, for selecting prompts
  field_key = "username"    # form field
  label     = "Username"    # label shown next/to above
  type      = "username"
  required  = true
  sub_text  = "Choose a good hackername" # help text
  # placeholder              = "MYUSERNAME"
  # placeholder_expression   = false
  # initial_value            = "MYUSERNAME"
  # initial_value_expression = false
  order = 0
}

resource "authentik_stage_prompt" "ii-enrollment-prompt" {
  name = "ii-enrollment-prompt"
  fields = [
    resource.authentik_stage_prompt_field.username.id,
  ]
  # validation_policies = [
  #   ""
  # ]
}


