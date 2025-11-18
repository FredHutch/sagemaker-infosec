variable "aws_region" {
  description = "AWS region for SageMaker deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "sagemaker_domain_name" {
  description = "Name of the SageMaker Domain"
  type        = string
  default     = "infosec-ml-domain"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "enable_vpn_gateway" {
  description = "Enable VPN gateway for VPC"
  type        = bool
  default     = false
}

variable "identity_center_instance_arn" {
  description = "ARN of IAM Identity Center instance"
  type        = string
}

variable "kms_key_administrators" {
  description = "List of IAM ARNs for KMS key administrators"
  type        = list(string)
  default     = []
}

variable "kms_key_users" {
  description = "List of IAM ARNs for KMS key users"
  type        = list(string)
  default     = []
}

variable "secrets_manager_arns" {
  description = "List of Secrets Manager ARNs for API credentials"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  type        = string
  default     = ""
}
