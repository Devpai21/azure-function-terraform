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