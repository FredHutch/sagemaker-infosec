variable "project_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "retention_days" {
  type    = number
  default = 90
}
