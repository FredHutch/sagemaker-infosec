output "workspace_id" {
  description = "ML Workspace ID"
  value       = azurerm_machine_learning_workspace.workspace.id
}

output "workspace_name" {
  description = "ML Workspace name"
  value       = azurerm_machine_learning_workspace.workspace.name
}

output "discovery_url" {
  description = "ML Workspace discovery URL"
  value       = azurerm_machine_learning_workspace.workspace.discovery_url
}
