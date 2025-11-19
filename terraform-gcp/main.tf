terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC Network
module "vpc" {
  source = "./modules/vpc"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
}

# Secret Manager for credentials
module "secret_manager" {
  source = "./modules/secret_manager"

  project_id  = var.project_id
  environment = var.environment
}

# Cloud Storage buckets
module "storage" {
  source = "./modules/storage"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
}

# Artifact Registry for container images
module "artifact_registry" {
  source = "./modules/artifact_registry"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
}

# Vertex AI Workbench
module "vertex_ai_workbench" {
  source = "./modules/vertex_ai_workbench"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  zone        = var.zone

  network_id  = module.vpc.network_id
  subnet_id   = module.vpc.subnet_id

  machine_type         = var.workbench_machine_type
  boot_disk_size_gb    = var.workbench_boot_disk_size_gb
  enable_gpu           = var.enable_gpu
  gpu_type             = var.gpu_type
  gpu_count            = var.gpu_count
}

# Service account for Vertex AI
resource "google_service_account" "vertex_ai" {
  account_id   = "vertex-ai-${var.environment}"
  display_name = "Vertex AI Service Account for InfoSec ML"
  project      = var.project_id
}

# IAM bindings
module "iam" {
  source = "./modules/iam"

  project_id         = var.project_id
  service_account_email = google_service_account.vertex_ai.email
  storage_bucket_names  = module.storage.bucket_names
}

# Cloud Logging
module "logging" {
  source = "./modules/logging"

  project_id  = var.project_id
  environment = var.environment
  retention_days = var.log_retention_days
}

# Cloud Monitoring
module "monitoring" {
  source = "./modules/monitoring"

  project_id         = var.project_id
  environment        = var.environment
  notification_channels = var.notification_channels
}

# Security Command Center (if enabled)
module "security_command_center" {
  source = "./modules/security_command_center"
  count  = var.enable_security_command_center ? 1 : 0

  organization_id = var.organization_id
  project_id      = var.project_id
}
