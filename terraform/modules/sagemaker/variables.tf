variable "domain_name" {
  description = "SageMaker domain name"
  type        = string
}

variable "auth_mode" {
  description = "Authentication mode (IAM or SSO)"
  type        = string
  default     = "IAM"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for SageMaker"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
}

variable "execution_role_arn" {
  description = "IAM execution role ARN"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

variable "identity_center_instance" {
  description = "IAM Identity Center instance ARN"
  type        = string
  default     = ""
}

variable "enable_jupyter_lab" {
  description = "Enable Jupyter Lab"
  type        = bool
  default     = true
}

variable "enable_kernel_gateway" {
  description = "Enable Kernel Gateway"
  type        = bool
  default     = true
}

variable "enable_network_isolation" {
  description = "Enable network isolation"
  type        = bool
  default     = false
}

variable "default_instance_type" {
  description = "Default instance type for notebooks"
  type        = string
  default     = "ml.t3.medium"
}

variable "jupyter_server_image_arn" {
  description = "Custom Jupyter server image ARN"
  type        = string
  default     = null
}

variable "kernel_gateway_image_arn" {
  description = "Custom kernel gateway image ARN"
  type        = string
  default     = null
}

variable "code_repository_url" {
  description = "Git repository URL for notebooks"
  type        = string
  default     = ""
}

variable "notebooks_bucket" {
  description = "S3 bucket for notebooks"
  type        = string
  default     = ""
}

variable "data_bucket" {
  description = "S3 bucket for security data"
  type        = string
  default     = ""
}

variable "security_team_users" {
  description = "Map of security team users"
  type = map(object({
    instance_type = optional(string)
    team         = string
  }))
  default = {}
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
