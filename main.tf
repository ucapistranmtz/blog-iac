terraform {
  backend "s3" {
    bucket         = "ucapistran-terraform-state"
    key            = "blog/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "ucapistran-state-lock"

  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"

    }
  }
}


provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "tf-blog-website-bucket" {
  bucket = var.bucket_name
  tags = {
    Name        = var.project_name
    Environment = var.environment
  }
}


resource "aws_s3_bucket_website_configuration" "blog_config" {
  bucket = aws_s3_bucket.tf-blog-website-bucket.id

  index_document {
    suffix = "index.html"
  }


  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "blog_public_access" {
  bucket = aws_s3_bucket.tf-blog-website-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

}

resource "aws_s3_bucket_policy" "public_read_policy" {
  depends_on = [aws_s3_bucket_public_access_block.blog_public_access]
  bucket     = aws_s3_bucket.tf-blog-website-bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.tf-blog-website-bucket.arn}/*"
      }
    ]
  })


}
