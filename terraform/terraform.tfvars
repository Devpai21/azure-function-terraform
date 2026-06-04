# terraform.tfvars
# Actual values for variables defined in variables.tf
# Safe to commit — contains no secrets or credentials
# For sensitive overrides create a local.tfvars file (excluded via .gitignore)

resource_group_name   = "func-demo-rg"
location              = "westus2"
storage_account_name  = "funcdemostore21tf"
app_service_plan_name = "func-demo-plan"
function_app_name     = "func-demo-app-21tf"
app_insights_name     = "func-demo-insights"
environment           = "dev"
owner                 = "devpai21"