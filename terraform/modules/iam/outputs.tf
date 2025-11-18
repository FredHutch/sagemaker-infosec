output "sagemaker_execution_role_arn" {
  description = "SageMaker execution role ARN"
  value       = aws_iam_role.sagemaker_execution.arn
}

output "sagemaker_execution_role_name" {
  description = "SageMaker execution role name"
  value       = aws_iam_role.sagemaker_execution.name
}

output "security_analyst_policy_arn" {
  description = "Security analyst policy ARN"
  value       = aws_iam_policy.security_analyst.arn
}

output "identity_center_role_arn" {
  description = "Identity Center SageMaker role ARN"
  value       = var.identity_center_instance_arn != "" ? aws_iam_role.identity_center_sagemaker[0].arn : ""
}
