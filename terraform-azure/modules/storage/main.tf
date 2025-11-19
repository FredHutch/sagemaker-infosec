resource "azurerm_storage_account" "storage" {
  name                     = "st${var.environment}infosec${random_string.suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"

  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [var.subnet_id]
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

# Storage containers
resource "azurerm_storage_container" "security_data" {
  name                  = "security-data"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "ml_models" {
  name                  = "ml-models"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "notebooks" {
  name                  = "notebooks"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}
