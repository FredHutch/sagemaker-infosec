resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "log-${var.environment}-infosec-ml"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_days

  tags = {
    Environment = var.environment
  }
}
