resource "google_storage_bucket" "security_data" {
  name          = "${var.project_id}-security-data-${var.environment}"
  location      = var.region
  project       = var.project_id
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 180
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  labels = {
    environment = var.environment
    purpose     = "security-data"
  }
}

resource "google_storage_bucket" "ml_models" {
  name          = "${var.project_id}-ml-models-${var.environment}"
  location      = var.region
  project       = var.project_id
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  labels = {
    environment = var.environment
    purpose     = "ml-models"
  }
}

resource "google_storage_bucket" "notebooks" {
  name          = "${var.project_id}-notebooks-${var.environment}"
  location      = var.region
  project       = var.project_id
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  labels = {
    environment = var.environment
    purpose     = "notebooks"
  }
}

resource "google_storage_bucket" "logs" {
  name          = "${var.project_id}-logs-${var.environment}"
  location      = var.region
  project       = var.project_id
  force_destroy = false

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = var.environment
    purpose     = "logs"
  }
}
