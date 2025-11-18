output "sagemaker_domain_id" {
  description = "SageMaker Domain ID"
  value       = module.sagemaker_domain.domain_id
}

output "sagemaker_domain_arn" {
  description = "SageMaker Domain ARN"
  value       = module.sagemaker_domain.domain_arn
}

output "sagemaker_domain_url" {
  description = "SageMaker Domain URL"
  value       = module.sagemaker_domain.domain_url
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "sagemaker_execution_role_arn" {
  description = "SageMaker execution role ARN"
  value       = module.iam.sagemaker_execution_role_arn
}

output "data_bucket_name" {
  description = "S3 bucket for security data"
  value       = module.s3.data_bucket_name
}

output "models_bucket_name" {
  description = "S3 bucket for ML models"
  value       = module.s3.models_bucket_name
}

output "notebooks_bucket_name" {
  description = "S3 bucket for notebooks"
  value       = module.s3.notebooks_bucket_name
}

output "kms_key_id" {
  description = "KMS key ID for encryption"
  value       = module.kms.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN for encryption"
  value       = module.kms.key_arn
}
