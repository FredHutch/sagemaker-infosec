resource "google_logging_project_sink" "security_logs" {
  name        = "security-logs-${var.environment}"
  project     = var.project_id
  destination = "storage.googleapis.com/${google_storage_bucket.log_bucket.name}"

  filter = "resource.type=\"aiplatform.googleapis.com/Endpoint\" OR resource.type=\"aiplatform.googleapis.com/Model\""

  unique_writer_identity = true
}

resource "google_storage_bucket" "log_bucket" {
  name          = "${var.project_id}-security-logs-${var.environment}"
  location      = "US"
  project       = var.project_id
  force_destroy = false

  lifecycle_rule {
    condition {
      age = var.retention_days
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_iam_member" "log_writer" {
  bucket = google_storage_bucket.log_bucket.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.security_logs.writer_identity
}
