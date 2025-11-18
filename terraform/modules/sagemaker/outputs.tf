output "domain_id" {
  description = "SageMaker domain ID"
  value       = aws_sagemaker_domain.main.id
}

output "domain_arn" {
  description = "SageMaker domain ARN"
  value       = aws_sagemaker_domain.main.arn
}

output "domain_url" {
  description = "SageMaker domain URL"
  value       = aws_sagemaker_domain.main.url
}

output "home_efs_file_system_id" {
  description = "EFS file system ID for home directories"
  value       = aws_sagemaker_domain.main.home_efs_file_system_id
}

output "user_profile_arns" {
  description = "User profile ARNs"
  value       = { for k, v in aws_sagemaker_user_profile.security_analysts : k => v.arn }
}

output "threat_hunting_space_arn" {
  description = "Threat hunting space ARN"
  value       = aws_sagemaker_space.threat_hunting.arn
}

output "incident_response_space_arn" {
  description = "Incident response space ARN"
  value       = aws_sagemaker_space.incident_response.arn
}
