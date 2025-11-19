resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "infosec-ml-${var.environment}"
  description   = "Docker repository for InfoSec ML containers"
  format        = "DOCKER"
  project       = var.project_id

  labels = {
    environment = var.environment
  }
}
