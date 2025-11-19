# Enable Security Command Center API
resource "google_project_service" "scc" {
  project = var.project_id
  service = "securitycenter.googleapis.com"

  disable_on_destroy = false
}

# Note: Full SCC configuration requires organization-level permissions
# This is a placeholder for SCC integration
