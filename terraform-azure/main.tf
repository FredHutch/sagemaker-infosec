terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azuread" {
}

# Resource Group
resource "azurerm_resource_group" "infosec" {
  name     = "rg-${var.environment}-infosec-ml"
  location = var.location

  tags = {
    Project     = "InfoSec-ML"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Virtual Network
module "vnet" {
  source = "./modules/vnet"

  resource_group_name = azurerm_resource_group.infosec.name
  location            = azurerm_resource_group.infosec.location
  environment         = var.environment
  vnet_address_space  = var.vnet_address_space
  subnet_prefixes     = var.subnet_prefixes
}

# Key Vault for secrets
module "key_vault" {
  source = "./modules/key_vault"

  resource_group_name = azurerm_resource_group.infosec.name
  location            = azurerm_resource_group.infosec.location
  environment         = var.environment
  tenant_id           = data.azuread_client_config.current.tenant_id

  # Grant access to current user/service principal
  key_vault_admins = var.key_vault_admins
}

# Storage Account
module "storage" {
  source = "./modules/storage"

  resource_group_name = azurerm_resource_group.infosec.name
  location            = azurerm_resource_group.infosec.location
  environment         = var.environment
  subnet_id           = module.vnet.ml_subnet_id
}

# Log Analytics Workspace
module "log_analytics" {
  source = "./modules/log_analytics"

  resource_group_name = azurerm_resource_group.infosec.name
  location            = azurerm_resource_group.infosec.location
  environment         = var.environment
  retention_days      = var.log_retention_days
}

# Application Insights
module "app_insights" {
  source = "./modules/app_insights"

  resource_group_name     = azurerm_resource_group.infosec.name
  location                = azurerm_resource_group.infosec.location
  environment             = var.environment
  log_analytics_workspace_id = module.log_analytics.workspace_id
}

# Container Registry for custom ML images
module "container_registry" {
  source = "./modules/container_registry"

  resource_group_name = azurerm_resource_group.infosec.name
  location            = azurerm_resource_group.infosec.location
  environment         = var.environment
  subnet_id           = module.vnet.ml_subnet_id
}

# Azure Machine Learning Workspace
module "ml_workspace" {
  source = "./modules/ml_workspace"

  resource_group_name         = azurerm_resource_group.infosec.name
  location                    = azurerm_resource_group.infosec.location
  environment                 = var.environment

  storage_account_id          = module.storage.storage_account_id
  key_vault_id                = module.key_vault.key_vault_id
  app_insights_id             = module.app_insights.app_insights_id
  container_registry_id       = module.container_registry.registry_id

  subnet_id                   = module.vnet.ml_subnet_id

  # Entra ID integration
  enable_entra_auth           = true

  # Compute configuration
  enable_compute_instance     = true
  compute_instance_vm_size    = var.compute_instance_vm_size
}

# Managed Identity for ML Workspace
resource "azurerm_user_assigned_identity" "ml_workspace" {
  name                = "id-${var.environment}-ml-workspace"
  resource_group_name = azurerm_resource_group.infosec.name
  location            = azurerm_resource_group.infosec.location
}

# Role assignments for security tool access
module "rbac" {
  source = "./modules/rbac"

  resource_group_name = azurerm_resource_group.infosec.name
  ml_identity_id      = azurerm_user_assigned_identity.ml_workspace.principal_id
  key_vault_id        = module.key_vault.key_vault_id
  storage_account_id  = module.storage.storage_account_id
}

# Security Center integration
module "security_center" {
  source = "./modules/security_center"

  resource_group_name     = azurerm_resource_group.infosec.name
  log_analytics_workspace_id = module.log_analytics.workspace_id
  enable_defender_for_servers = true
  enable_defender_for_storage = true
}

data "azuread_client_config" "current" {}
