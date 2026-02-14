terraform {
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

