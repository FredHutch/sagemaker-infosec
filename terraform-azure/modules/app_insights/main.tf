resource "azurerm_application_insights" "app_insights" {
  name                = "appi-${var.environment}-infosec-ml"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = var.log_analytics_workspace_id
  application_type    = "other"

  tags = {
    Environment = var.environment
  }
}
