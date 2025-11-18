variable "description" {
  description = "Description of the KMS key"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "deletion_window_in_days" {
  description = "Duration in days after which the key is deleted after destruction"
  type        = number
  default     = 30
}

variable "key_administrators" {
  description = "List of IAM ARNs for key administrators"
  type        = list(string)
  default     = []
}

variable "key_users" {
  description = "List of IAM ARNs for key users"
  type        = list(string)
  default     = []
}
