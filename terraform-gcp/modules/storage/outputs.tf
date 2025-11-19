output "bucket_names" {
  value = {
    security_data = google_storage_bucket.security_data.name
    ml_models     = google_storage_bucket.ml_models.name
    notebooks     = google_storage_bucket.notebooks.name
    logs          = google_storage_bucket.logs.name
  }
}
