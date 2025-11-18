output "data_bucket_name" {
  description = "Data bucket name"
  value       = var.create_data_bucket ? aws_s3_bucket.data[0].id : ""
}

output "data_bucket_arn" {
  description = "Data bucket ARN"
  value       = var.create_data_bucket ? aws_s3_bucket.data[0].arn : ""
}

output "models_bucket_name" {
  description = "Models bucket name"
  value       = var.create_models_bucket ? aws_s3_bucket.models[0].id : ""
}

output "models_bucket_arn" {
  description = "Models bucket ARN"
  value       = var.create_models_bucket ? aws_s3_bucket.models[0].arn : ""
}

output "notebooks_bucket_name" {
  description = "Notebooks bucket name"
  value       = var.create_notebooks_bucket ? aws_s3_bucket.notebooks[0].id : ""
}

output "notebooks_bucket_arn" {
  description = "Notebooks bucket ARN"
  value       = var.create_notebooks_bucket ? aws_s3_bucket.notebooks[0].arn : ""
}

output "logs_bucket_name" {
  description = "Logs bucket name"
  value       = var.create_logs_bucket ? aws_s3_bucket.logs[0].id : ""
}

output "logs_bucket_arn" {
  description = "Logs bucket ARN"
  value       = var.create_logs_bucket ? aws_s3_bucket.logs[0].arn : ""
}
