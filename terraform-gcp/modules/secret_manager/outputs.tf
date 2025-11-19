output "secret_ids" {
  value = {
    crowdstrike = google_secret_manager_secret.crowdstrike.secret_id
    microsoft   = google_secret_manager_secret.microsoft.secret_id
    proofpoint  = google_secret_manager_secret.proofpoint.secret_id
  }
}
