resource "azurerm_container_registry" "acr" {
  name                = "acr${var.environment}infosec${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Premium"
  admin_enabled       = false

  public_network_access_enabled = false

  network_rule_set {
    default_action = "Deny"

    virtual_network {
      action    = "Allow"
      subnet_id = var.subnet_id
    }
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
