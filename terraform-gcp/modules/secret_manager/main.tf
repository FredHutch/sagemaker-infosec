resource "google_secret_manager_secret" "crowdstrike" {
  secret_id = "crowdstrike-api-credentials-${var.environment}"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
  }
}

resource "google_secret_manager_secret_version" "crowdstrike" {
  secret = google_secret_manager_secret.crowdstrike.id

  secret_data = jsonencode({
    client_id     = "REPLACE_WITH_ACTUAL_VALUE"
    client_secret = "REPLACE_WITH_ACTUAL_VALUE"
  })
}

resource "google_secret_manager_secret" "microsoft" {
  secret_id = "microsoft-api-credentials-${var.environment}"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
  }
}

resource "google_secret_manager_secret_version" "microsoft" {
  secret = google_secret_manager_secret.microsoft.id

  secret_data = jsonencode({
    tenant_id     = "REPLACE_WITH_ACTUAL_VALUE"
    client_id     = "REPLACE_WITH_ACTUAL_VALUE"
    client_secret = "REPLACE_WITH_ACTUAL_VALUE"
  })
}

resource "google_secret_manager_secret" "proofpoint" {
  secret_id = "proofpoint-api-credentials-${var.environment}"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
  }
}

resource "google_secret_manager_secret_version" "proofpoint" {
  secret = google_secret_manager_secret.proofpoint.id

  secret_data = jsonencode({
    service_principal = "REPLACE_WITH_ACTUAL_VALUE"
    secret            = "REPLACE_WITH_ACTUAL_VALUE"
  })
}
