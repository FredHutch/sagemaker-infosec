variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "vnet_address_space" {
  description = "Address space for VNet"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "subnet_prefixes" {
  description = "Subnet prefixes"
  type = object({
    ml_subnet     = string
    compute_subnet = string
    pe_subnet     = string
  })
  default = {
    ml_subnet     = "10.1.1.0/24"
    compute_subnet = "10.1.2.0/24"
    pe_subnet     = "10.1.3.0/24"
  }
}

variable "key_vault_admins" {
  description = "List of object IDs for Key Vault administrators"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 90
}

variable "compute_instance_vm_size" {
  description = "VM size for compute instance"
  type        = string
  default     = "Standard_DS3_v2"
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints for services"
  type        = bool
  default     = true
}

variable "allowed_ip_ranges" {
  description = "Allowed IP ranges for access"
  type        = list(string)
  default     = []
}
