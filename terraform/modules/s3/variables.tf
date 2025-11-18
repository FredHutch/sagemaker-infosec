variable "environment" {
  description = "Environment name"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

variable "create_data_bucket" {
  description = "Create data bucket"
  type        = bool
  default     = true
}

variable "create_models_bucket" {
  description = "Create models bucket"
  type        = bool
  default     = true
}

variable "create_notebooks_bucket" {
  description = "Create notebooks bucket"
  type        = bool
  default     = true
}

variable "create_logs_bucket" {
  description = "Create logs bucket"
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "Enable versioning on buckets"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable access logging"
  type        = bool
  default     = true
}

variable "enable_lifecycle_policies" {
  description = "Enable lifecycle policies"
  type        = bool
  default     = true
}
