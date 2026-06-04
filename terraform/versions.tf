# versions.tf
# Defines the required Terraform version and provider dependencies
# Kept separate from main.tf for clarity and easier provider upgrades

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      # AzureRM provider — official Microsoft maintained provider for Azure resources
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}