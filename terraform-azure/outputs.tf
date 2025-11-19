output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.infosec.name
}

output "ml_workspace_id" {
  description = "Azure ML Workspace ID"
  value       = module.ml_workspace.workspace_id
}

output "ml_workspace_name" {
  description = "Azure ML Workspace name"
  value       = module.ml_workspace.workspace_name
}

output "storage_account_name" {
  description = "Storage account name"
  value       = module.storage.storage_account_name
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = module.key_vault.key_vault_name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = module.key_vault.key_vault_uri
}

output "vnet_id" {
  description = "Virtual Network ID"
  value       = module.vnet.vnet_id
}

output "ml_subnet_id" {
  description = "ML Subnet ID"
  value       = module.vnet.ml_subnet_id
}

output "container_registry_login_server" {
  description = "Container Registry login server"
  value       = module.container_registry.login_server
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = module.log_analytics.workspace_id
}

output "ml_workspace_endpoint" {
  description = "ML Workspace endpoint URL"
  value       = "https://ml.azure.com/?wsid=/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.infosec.name}/providers/Microsoft.MachineLearningServices/workspaces/${module.ml_workspace.workspace_name}"
}

data "azurerm_client_config" "current" {}
