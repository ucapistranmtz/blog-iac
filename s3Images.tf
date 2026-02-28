# --- Media Storage Bucket ---
resource "aws_s3_bucket" "blog_media" {
  bucket = "${var.project_name}-media-storage"

  lifecycle {
    prevent_destroy = false 
  }

  tags = {
    Name        = "Blog Media Storage"
    Environment = var.environment
  }
}

# --- CORS Configuration for Presigned URLs ---
resource "aws_s3_bucket_cors_configuration" "media_cors" {
  bucket = aws_s3_bucket.blog_media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    # For production, replace "*" with your CloudFront domain
    allowed_origins = ["*"] 
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# --- Block Public Access (Crucial for Best Practices) ---
resource "aws_s3_bucket_public_access_block" "media_access" {
  bucket = aws_s3_bucket.blog_media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- Unified Bucket Policy (CloudFront OAC only) ---
resource "aws_s3_bucket_policy" "media_bucket_policy" {
  bucket = aws_s3_bucket.blog_media.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.blog_media.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.media_distribution.arn
          }
        }
      }
    ]
  })
}