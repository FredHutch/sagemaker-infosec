output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.sagemaker.name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.sagemaker.arn
}

output "dashboard_arn" {
  description = "CloudWatch dashboard ARN"
  value       = aws_cloudwatch_dashboard.sagemaker_security.dashboard_arn
}
