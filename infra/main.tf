resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

# --- Resource Group ---
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.environment}"
  location = var.location
  tags     = var.tags
}

data "azurerm_client_config" "current" {}

# --- Key Vault ---
# Standard SKU: no fixed monthly fee, billed per operation (cents/month
# at this project's volume). RBAC instead of access policy (current default).
resource "azurerm_key_vault" "main" {
  name                       = "kv-${var.project}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  tags = var.tags
}

resource "azurerm_role_assignment" "kv_admin_deployer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# --- Storage Account + Queue (webhook -> worker queue) ---
resource "azurerm_storage_account" "main" {
  name                     = "st${var.project}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_storage_queue" "telegram_messages" {
  name                 = "telegram-messages"
  storage_account_name = azurerm_storage_account.main.name
}

# --- Log Analytics (required for Container Apps Environment) ---
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# --- Container Apps Environment ---
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.project}-${var.environment}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tags                       = var.tags
}

# --- Container App (API) ---
resource "azurerm_container_app" "api" {
  name                         = "ca-${var.project}-api"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  tags                         = var.tags

  identity {
    type = "SystemAssigned"
  }

  registry {
    server               = "ghcr.io"
    username             = "bielllb"
    password_secret_name = "ghcr-pat"
  }

  secret {
    name                = "ghcr-pat"
    key_vault_secret_id = "https://${azurerm_key_vault.main.name}.vault.azure.net/secrets/ghcr-pat"
    identity            = "System"
  }

  secret {
    name                = "database-url"
    key_vault_secret_id = "https://${azurerm_key_vault.main.name}.vault.azure.net/secrets/database-url"
    identity            = "System"
  }

  template {
    min_replicas = 0
    max_replicas = 2

    container {
      name   = "api"
      image  = "ghcr.io/bielllb/granabot:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name        = "DATABASE_URL"
        secret_name = "database-url"
      }

      env {
        name  = "PORT"
        value = "8080"
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# Container App's managed identity needs to read Key Vault secrets
resource "azurerm_role_assignment" "kv_secrets_reader" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_container_app.api.identity[0].principal_id
}