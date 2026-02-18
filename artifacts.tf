# --- Artifacts Storage for Lambda Zips ---

resource "aws_s3_bucket" "artifacts_storage" {
  # Standardized bucket name for storing Lambda deployments
  bucket = "${var.project_name}-artifacts"

  tags = {
    Name        = "${var.project_name}-artifacts"
    Environment = var.environment
    Service     = "CI-CD"
  }
}

# --- Security: Private Access Only ---

resource "aws_s3_bucket_public_access_block" "artifacts_storage_block" {
  bucket = aws_s3_bucket.artifacts_storage.id

  # Strict private settings: Lambda code should never be public
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- Versioning: Enable Rollbacks ---

resource "aws_s3_bucket_versioning" "artifacts_versioning" {
  bucket = aws_s3_bucket.artifacts_storage.id

  # Versioning is crucial for S3-based Lambda deployments to allow rollbacks
  versioning_configuration {
    status = "Enabled"
  }
}

# --- Outputs for CI/CD Pipelines ---

output "artifacts_bucket_name" {
  description = "Name of the S3 bucket used for Lambda artifacts"
  value       = aws_s3_bucket.artifacts_storage.id
}
