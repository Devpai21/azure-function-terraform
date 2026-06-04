# variables.tf
# Input variables for the Azure Function App infrastructure
# Override defaults by setting values in terraform.tfvars

# Resource Group
variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "func-demo-rg"
}

# Region
variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "westus2"
}

# Storage Account — required by Azure Functions runtime
variable "storage_account_name" {
  description = "Name of the Storage Account (must be globally unique, lowercase, 3-24 chars)"
  type        = string
  default     = "funcdemostore21tf"
}

# App Service Plan
variable "app_service_plan_name" {
  description = "Name of the App Service Plan (Consumption/Free tier)"
  type        = string
  default     = "func-demo-plan"
}

# Function App
variable "function_app_name" {
  description = "Name of the Function App (must be globally unique)"
  type        = string
  default     = "func-demo-app-21tf"
}

# Application Insights
variable "app_insights_name" {
  description = "Name of the Application Insights instance"
  type        = string
  default     = "func-demo-insights"
}

# Tags
variable "environment" {
  description = "Environment tag applied to all resources"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner tag applied to all resources"
  type        = string
  default     = "devpai21"
}