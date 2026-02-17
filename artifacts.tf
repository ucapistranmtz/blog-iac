
resource "aws_s3_bucket" "artifacts_storage" {
  bucket = "${var.project_name}-artifacts"

  tags = {
    Name        = "${var.project_name}-artifacts"
    Environment = var.environment
    Service     = "CI-CD"
  }
}


resource "aws_s3_bucket_public_access_block" "artifacts_storage_block" {
  bucket = aws_s3_bucket.artifacts_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_versioning" "artifacts_versioning" {
  bucket = aws_s3_bucket.artifacts_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}
