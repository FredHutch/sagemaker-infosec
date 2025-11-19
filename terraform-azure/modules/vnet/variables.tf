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

variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
}

variable "subnet_prefixes" {
  description = "Subnet prefixes"
  type = object({
    ml_subnet      = string
    compute_subnet = string
    pe_subnet      = string
  })
}
