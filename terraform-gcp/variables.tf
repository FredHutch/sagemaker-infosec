variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "organization_id" {
  description = "GCP Organization ID (for Security Command Center)"
  type        = string
  default     = ""
}

variable "workbench_machine_type" {
  description = "Machine type for Vertex AI Workbench"
  type        = string
  default     = "n1-standard-4"
}

variable "workbench_boot_disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 100
}

variable "enable_gpu" {
  description = "Enable GPU for workbench instance"
  type        = bool
  default     = false
}

variable "gpu_type" {
  description = "GPU type"
  type        = string
  default     = "NVIDIA_TESLA_T4"
}

variable "gpu_count" {
  description = "Number of GPUs"
  type        = number
  default     = 1
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 90
}

variable "notification_channels" {
  description = "List of notification channel IDs"
  type        = list(string)
  default     = []
}

variable "enable_security_command_center" {
  description = "Enable Security Command Center"
  type        = bool
  default     = false
}

variable "allowed_ip_ranges" {
  description = "Allowed IP ranges for access"
  type        = list(string)
  default     = []
}
