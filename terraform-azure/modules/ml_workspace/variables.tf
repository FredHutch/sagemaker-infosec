variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "storage_account_id" {
  description = "Storage Account ID"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault ID"
  type        = string
}

variable "app_insights_id" {
  description = "Application Insights ID"
  type        = string
}

variable "container_registry_id" {
  description = "Container Registry ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for ML workspace"
  type        = string
}

variable "enable_entra_auth" {
  description = "Enable Entra ID authentication"
  type        = bool
  default     = true
}

variable "enable_compute_instance" {
  description = "Enable compute instance"
  type        = bool
  default     = true
}

variable "compute_instance_vm_size" {
  description = "VM size for compute instance"
  type        = string
  default     = "Standard_DS3_v2"
}

variable "ssh_public_key" {
  description = "SSH public key for compute instance"
  type        = string
  default     = ""
  sensitive   = true
}
