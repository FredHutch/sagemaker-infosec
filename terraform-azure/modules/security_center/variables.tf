variable "resource_group_name" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "enable_defender_for_servers" {
  type    = bool
  default = true
}

variable "enable_defender_for_storage" {
  type    = bool
  default = true
}
