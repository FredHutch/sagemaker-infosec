output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = azurerm_virtual_network.vnet.name
}

output "ml_subnet_id" {
  description = "ML Subnet ID"
  value       = azurerm_subnet.ml_subnet.id
}

output "compute_subnet_id" {
  description = "Compute Subnet ID"
  value       = azurerm_subnet.compute_subnet.id
}

output "pe_subnet_id" {
  description = "Private Endpoint Subnet ID"
  value       = azurerm_subnet.pe_subnet.id
}
