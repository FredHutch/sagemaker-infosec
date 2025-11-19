variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "environment" {
  type = string
}

variable "network_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "machine_type" {
  type    = string
  default = "n1-standard-4"
}

variable "boot_disk_size_gb" {
  type    = number
  default = 100
}

variable "enable_gpu" {
  type    = bool
  default = false
}

variable "gpu_type" {
  type    = string
  default = "NVIDIA_TESLA_T4"
}

variable "gpu_count" {
  type    = number
  default = 1
}
