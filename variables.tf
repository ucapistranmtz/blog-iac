variable "aws_region" {
  description = "AWS region where the bucket will be created"
  type        = string
  default     = "us-east-1"
}


variable "bucket_name" {
  description = "unique name of the bucket"
  type        = string
  default     = "ucapistran-blog"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "blog-website"
}

variable "environment" {
  description = "Execution environment"
  type        = string
  default     = "dev" # dev,stage,prod
}


variable "database_url" {
  description = "neon database url"
  type        = string
  sensitive   = true
  default     = "change_this_db_url"
}

variable "better_auth_secret" {
  description = "better auth secret"
  type        = string
  sensitive   = true
  default     = "change_this_secret"
}
