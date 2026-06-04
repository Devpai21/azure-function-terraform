# outputs.tf
# Values printed after terraform apply completes
# Use these to quickly validate and test the deployment

# Confirm which resource group was created
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

# Confirm function app name for CLI deployment
output "function_app_name" {
  description = "Name of the Function App"
  value       = azurerm_windows_function_app.func.name
}

# Full URL to invoke the function — use this to test after deployment
output "function_app_url" {
  description = "Default hostname of the Function App"
  value       = "https://${azurerm_windows_function_app.func.default_hostname}"
}

# App Insights key — marked sensitive so it never prints in plain text or logs
output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.insights.instrumentation_key
  sensitive   = true
}