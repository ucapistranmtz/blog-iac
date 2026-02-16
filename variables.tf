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
