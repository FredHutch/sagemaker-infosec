output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP Region"
  value       = var.region
}

output "workbench_instance_name" {
  description = "Vertex AI Workbench instance name"
  value       = module.vertex_ai_workbench.instance_name
}

output "workbench_proxy_uri" {
  description = "Vertex AI Workbench JupyterLab URI"
  value       = module.vertex_ai_workbench.proxy_uri
}

output "storage_buckets" {
  description = "Cloud Storage bucket names"
  value       = module.storage.bucket_names
}

output "service_account_email" {
  description = "Service account email for Vertex AI"
  value       = google_service_account.vertex_ai.email
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository name"
  value       = module.artifact_registry.repository_name
}

output "vpc_network_name" {
  description = "VPC network name"
  value       = module.vpc.network_name
}

output "workbench_access_url" {
  description = "URL to access Vertex AI Workbench"
  value       = "https://console.cloud.google.com/vertex-ai/workbench/instances?project=${var.project_id}"
}
