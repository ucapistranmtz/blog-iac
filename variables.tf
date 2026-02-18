# --- Region & Project Identity ---

variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project used as a prefix for all resources"
  type        = string
  default     = "blog-website"
}

variable "environment" {
  description = "Deployment environment (dev, stage, prod)"
  type        = string
  default     = "dev"
}

# --- S3 Hosting Configuration ---

variable "bucket_name" {
  description = "Globally unique name for the S3 bucket hosting the Next.js frontend"
  type        = string
  default     = "ucapistran-blog"
}

# --- REMOVED: database_url (Neon is no longer used) ---
# --- REMOVED: better_auth_secret (Better Auth is no longer used) ---
