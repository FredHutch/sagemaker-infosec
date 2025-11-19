resource "azurerm_machine_learning_workspace" "workspace" {
  name                    = "mlw-${var.environment}-infosec"
  location                = var.location
  resource_group_name     = var.resource_group_name
  application_insights_id = var.app_insights_id
  key_vault_id            = var.key_vault_id
  storage_account_id      = var.storage_account_id
  container_registry_id   = var.container_registry_id

  identity {
    type = "SystemAssigned"
  }

  public_network_access_enabled = false

  tags = {
    Environment = var.environment
    Purpose     = "Security-ML"
  }
}

# Compute instance for notebook development
resource "azurerm_machine_learning_compute_instance" "dev_instance" {
  count = var.enable_compute_instance ? 1 : 0

  name                          = "ci-${var.environment}-security-analyst"
  location                      = var.location
  machine_learning_workspace_id = azurerm_machine_learning_workspace.workspace.id
  virtual_machine_size          = var.compute_instance_vm_size

  subnet_resource_id = var.subnet_id

  assign_to_user {
    tenant_id = data.azurerm_client_config.current.tenant_id
  }

  ssh {
    public_key = var.ssh_public_key != "" ? var.ssh_public_key : null
  }
}

# Compute cluster for training jobs
resource "azurerm_machine_learning_compute_cluster" "training_cluster" {
  name                          = "cc-${var.environment}-training"
  location                      = var.location
  vm_priority                   = "Dedicated"
  vm_size                       = "Standard_DS3_v2"
  machine_learning_workspace_id = azurerm_machine_learning_workspace.workspace.id
  subnet_resource_id            = var.subnet_id

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = 4
    scale_down_nodes_after_idle_duration = "PT30M"
  }

  identity {
    type = "SystemAssigned"
  }
}

data "azurerm_client_config" "current" {}
