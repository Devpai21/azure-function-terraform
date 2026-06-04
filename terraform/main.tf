# main.tf
# Core infrastructure for Azure Function App
# Provisions all required Azure resources using the AzureRM provider

provider "azurerm" {
  # prevent_deletion_if_contains_resources = false prevents Terraform from
  # blocking resource group deletion when auto-generated resources exist
  # (e.g. Application Insights Smart Detection action groups)
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Resource Group — logical container for all resources
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = var.environment
    owner       = var.owner
  }
}

# Storage Account — required by Azure Functions runtime
# Stores function state, logs, and triggers
# Must be globally unique, lowercase, 3-24 chars
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Explicit dependency ensures resource group is fully created first
  # Prevents race condition that causes 404 errors during parallel creation
  depends_on = [azurerm_resource_group.rg]

  tags = {
    environment = var.environment
    owner       = var.owner
  }
}

# App Service Plan — Consumption (Y1) Free tier
# sku_name Y1 = Consumption plan — scales to zero, pay per execution
# os_type Windows required for Consumption plan availability
resource "azurerm_service_plan" "plan" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Windows"
  sku_name            = "Y1"

  tags = {
    environment = var.environment
    owner       = var.owner
  }
}

# Application Insights — monitoring and observability
# Tracks requests, failures, performance, and logs
resource "azurerm_application_insights" "insights" {
  name                = var.app_insights_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  application_type    = "web"

  tags = {
    environment = var.environment
    owner       = var.owner
  }
}

# Azure Function App — Windows Consumption plan
# Uses dotnet-isolated runtime for .NET 8
# dotnet-isolated = function runs in separate process from host (modern best practice)
resource "azurerm_windows_function_app" "func" {
  name                       = var.function_app_name
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  service_plan_id            = azurerm_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key
  public_network_access_enabled = true

  site_config {
    application_stack {
      # v8.0 prefix required for Windows function apps
      dotnet_version              = "v8.0"
      use_dotnet_isolated_runtime = true
    }
  }

  app_settings = {
    # Wire up Application Insights for monitoring
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.insights.instrumentation_key
    # Tell the runtime to use dotnet-isolated worker
    FUNCTIONS_WORKER_RUNTIME       = "dotnet-isolated"
    # Pin to Functions runtime v4
    FUNCTIONS_EXTENSION_VERSION    = "~4"
  }

  tags = {
    environment = var.environment
    owner       = var.owner
  }
}

# =============================================================================
# BONUS: Private Endpoint Configuration
# =============================================================================
# NOTE: Private Endpoints are NOT supported on the Consumption (Y1) plan.
# This is a known Azure platform limitation. The configuration below
# demonstrates the correct infrastructure pattern for production use.
#
# To enable Private Endpoint support:
# 1. Run terraform destroy to remove existing resources
# 2. Change sku_name from "Y1" to "EP1" in the azurerm_service_plan resource
# 3. Uncomment all resources below
# 4. Run terraform validate
# 5. Run terraform apply
#
# Reference: https://learn.microsoft.com/en-us/azure/azure-functions/functions-networking-options
# =============================================================================

# # Virtual Network — required for Private Endpoint
# # Provides the network boundary for private connectivity
# resource "azurerm_virtual_network" "vnet" {
#   name                = "func-demo-vnet"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   address_space       = ["10.0.0.0/16"]
#
#   tags = {
#     environment = var.environment
#     owner       = var.owner
#   }
# }

# # Subnet — dedicated subnet for Private Endpoint
# # Private endpoints require their own subnet
# resource "azurerm_subnet" "pe_subnet" {
#   name                 = "func-demo-pe-subnet"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = ["10.0.1.0/24"]
# }

# # Private DNS Zone — resolves function hostname to private IP inside VNet
# # privatelink.azurewebsites.net is the standard zone for Azure Functions
# resource "azurerm_private_dns_zone" "dns_zone" {
#   name                = "privatelink.azurewebsites.net"
#   resource_group_name = azurerm_resource_group.rg.name
#
#   tags = {
#     environment = var.environment
#     owner       = var.owner
#   }
# }

# # DNS Zone VNet Link — connects Private DNS Zone to VNet
# # Ensures DNS resolution works for resources inside the VNet
# # registration_enabled = false because we are not auto-registering VM DNS records
# resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
#   name                  = "func-demo-dns-link"
#   resource_group_name   = azurerm_resource_group.rg.name
#   private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
#   virtual_network_id    = azurerm_virtual_network.vnet.id
#   registration_enabled  = false
#
#   tags = {
#     environment = var.environment
#     owner       = var.owner
#   }
# }

# # Private Endpoint — creates private IP for Function App inside VNet
# # Allows resources in the VNet to reach the function without public internet
# # subresource_names = ["sites"] is the correct subresource for Azure Functions
# resource "azurerm_private_endpoint" "pe" {
#   name                = "func-demo-pe"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   subnet_id           = azurerm_subnet.pe_subnet.id
#
#   private_service_connection {
#     name                           = "func-demo-pe-connection"
#     private_connection_resource_id = azurerm_windows_function_app.func.id
#     subresource_names              = ["sites"]
#     is_manual_connection           = false
#   }
#
#   private_dns_zone_group {
#     name                 = "func-demo-dns-group"
#     private_dns_zone_ids = [azurerm_private_dns_zone.dns_zone.id]
#   }
#
#   tags = {
#     environment = var.environment
#     owner       = var.owner
#   }
# }