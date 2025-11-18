variable "environment" {
  description = "Environment name"
  type        = string
}

variable "sagemaker_domain_name" {
  description = "SageMaker domain name"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "identity_center_instance_arn" {
  description = "IAM Identity Center instance ARN"
  type        = string
  default     = ""
}

variable "enable_crowdstrike_access" {
  description = "Enable CrowdStrike API access"
  type        = bool
  default     = false
}

variable "enable_microsoft_access" {
  description = "Enable Microsoft security tools access"
  type        = bool
  default     = false
}

variable "enable_proofpoint_access" {
  description = "Enable Proofpoint API access"
  type        = bool
  default     = false
}

variable "secrets_manager_arns" {
  description = "List of Secrets Manager ARNs"
  type        = list(string)
  default     = ["*"]
}
