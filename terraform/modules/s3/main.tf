locals {
  bucket_prefix = "${var.environment}-sagemaker-infosec"
}

# Data bucket for security datasets
resource "aws_s3_bucket" "data" {
  count  = var.create_data_bucket ? 1 : 0
  bucket = "${local.bucket_prefix}-data"

  tags = {
    Name        = "SageMaker InfoSec Data"
    Environment = var.environment
    Purpose     = "SecurityData"
  }
}

# Models bucket for ML models
resource "aws_s3_bucket" "models" {
  count  = var.create_models_bucket ? 1 : 0
  bucket = "${local.bucket_prefix}-models"

  tags = {
    Name        = "SageMaker InfoSec Models"
    Environment = var.environment
    Purpose     = "MLModels"
  }
}

# Notebooks bucket for shared notebooks
resource "aws_s3_bucket" "notebooks" {
  count  = var.create_notebooks_bucket ? 1 : 0
  bucket = "${local.bucket_prefix}-notebooks"

  tags = {
    Name        = "SageMaker InfoSec Notebooks"
    Environment = var.environment
    Purpose     = "Notebooks"
  }
}

# Logs bucket
resource "aws_s3_bucket" "logs" {
  count  = var.create_logs_bucket ? 1 : 0
  bucket = "${local.bucket_prefix}-logs"

  tags = {
    Name        = "SageMaker InfoSec Logs"
    Environment = var.environment
    Purpose     = "Logs"
  }
}

# Versioning
resource "aws_s3_bucket_versioning" "data" {
  count  = var.create_data_bucket && var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.data[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "models" {
  count  = var.create_models_bucket && var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.models[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "notebooks" {
  count  = var.create_notebooks_bucket && var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.notebooks[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  count  = var.create_data_bucket ? 1 : 0
  bucket = aws_s3_bucket.data[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "models" {
  count  = var.create_models_bucket ? 1 : 0
  bucket = aws_s3_bucket.models[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "notebooks" {
  count  = var.create_notebooks_bucket ? 1 : 0
  bucket = aws_s3_bucket.notebooks[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count  = var.create_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = true
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "data" {
  count  = var.create_data_bucket ? 1 : 0
  bucket = aws_s3_bucket.data[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "models" {
  count  = var.create_models_bucket ? 1 : 0
  bucket = aws_s3_bucket.models[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "notebooks" {
  count  = var.create_notebooks_bucket ? 1 : 0
  bucket = aws_s3_bucket.notebooks[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count  = var.create_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Logging
resource "aws_s3_bucket_logging" "data" {
  count  = var.create_data_bucket && var.enable_logging && var.create_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.data[0].id

  target_bucket = aws_s3_bucket.logs[0].id
  target_prefix = "data-bucket/"
}

resource "aws_s3_bucket_logging" "models" {
  count  = var.create_models_bucket && var.enable_logging && var.create_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.models[0].id

  target_bucket = aws_s3_bucket.logs[0].id
  target_prefix = "models-bucket/"
}

resource "aws_s3_bucket_logging" "notebooks" {
  count  = var.create_notebooks_bucket && var.enable_logging && var.create_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.notebooks[0].id

  target_bucket = aws_s3_bucket.logs[0].id
  target_prefix = "notebooks-bucket/"
}

# Lifecycle policies
resource "aws_s3_bucket_lifecycle_configuration" "data" {
  count  = var.create_data_bucket && var.enable_lifecycle_policies ? 1 : 0
  bucket = aws_s3_bucket.data[0].id

  rule {
    id     = "transition-old-data"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count  = var.create_logs_bucket && var.enable_lifecycle_policies ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}
