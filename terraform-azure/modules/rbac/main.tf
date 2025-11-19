# Key Vault access for ML workspace identity
resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.ml_identity_id
}

# Storage access for ML workspace identity
resource "azurerm_role_assignment" "storage_contributor" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.ml_identity_id
}
