data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                        = "kv-${var.environment}-infosec-${random_string.suffix.result}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id
  sku_name                    = "premium"
  soft_delete_retention_days  = 90
  purge_protection_enabled    = true
  enable_rbac_authorization   = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = {
    Environment = var.environment
  }
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# RBAC role assignments for Key Vault
resource "azurerm_role_assignment" "kv_admin" {
  for_each             = toset(var.key_vault_admins)
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Store example secrets for security tools
resource "azurerm_key_vault_secret" "crowdstrike_placeholder" {
  name         = "crowdstrike-api-credentials"
  value        = jsonencode({
    client_id     = "REPLACE_WITH_ACTUAL_VALUE"
    client_secret = "REPLACE_WITH_ACTUAL_VALUE"
  })
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_role_assignment.kv_secrets_user]
}

resource "azurerm_key_vault_secret" "microsoft_placeholder" {
  name         = "microsoft-api-credentials"
  value        = jsonencode({
    tenant_id     = "REPLACE_WITH_ACTUAL_VALUE"
    client_id     = "REPLACE_WITH_ACTUAL_VALUE"
    client_secret = "REPLACE_WITH_ACTUAL_VALUE"
  })
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_role_assignment.kv_secrets_user]
}

resource "azurerm_key_vault_secret" "proofpoint_placeholder" {
  name         = "proofpoint-api-credentials"
  value        = jsonencode({
    service_principal = "REPLACE_WITH_ACTUAL_VALUE"
    secret           = "REPLACE_WITH_ACTUAL_VALUE"
  })
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_role_assignment.kv_secrets_user]
}
