# Enable Microsoft Defender for Cloud
resource "azurerm_security_center_workspace" "workspace" {
  scope        = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  workspace_id = var.log_analytics_workspace_id
}

data "azurerm_client_config" "current" {}
