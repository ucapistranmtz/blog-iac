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
 
resource "aws_s3_bucket_cors_configuration" "media_cors" {
  bucket = aws_s3_bucket.blog_media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"] # En prod, cámbialo a tu dominio real
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

 
resource "aws_s3_bucket_public_access_block" "media_access" {
  bucket = aws_s3_bucket.blog_media.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

 resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = aws_s3_bucket.blog_media.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.blog_media.arn}/blog/images/*"
      }
    ]
  })
  
  depends_on = [aws_s3_bucket_public_access_block.media_access]
}