 # --- Origin Access Control for the Frontend Website ---
resource "aws_cloudfront_origin_access_control" "website_oac" {
  name                              = "${var.project_name}-website-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# --- Website Distribution ---
resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    domain_name              = aws_s3_bucket.tf-blog-website-bucket.bucket_regional_domain_name
    origin_id                = "${var.project_name}-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.website_oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # Support for Next.js client-side routing
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.project_name}-frontend"

    forwarded_values {
      query_string = false
      cookies      { forward = "none" }
    }

    viewer_protocol_policy = "redirect-to-https"
    compress               = true # Enables Gzip/Brotli compression
    
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}