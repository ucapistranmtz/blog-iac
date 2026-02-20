# --- DynamoDB Main Table ---

resource "aws_dynamodb_table" "blog_table" {
  name         = "${var.project_name}-table"
  billing_mode = "PAY_PER_REQUEST" # Ultra-cheap: Pay only for actual usage (On-Demand)

  # Partition Key (Primary Key)
  hash_key = "PK"

  # Sort Key (For advanced filtering and grouping)
  range_key = "SK"

  # Attribute definitions for the Keys
  attribute {
    name = "PK"
    type = "S" # String
  }

  # Global Secondary Index for querying data by date or type if needed later
  # For now, we keep it simple to avoid extra costs.
  attribute {
    name = "SK"
    type = "S" # String
  }

  global_secondary_index {
    name     = "SlugIndex"
    hash_key = "slug" # In AWS Provider 6.x, this is still hash_key, 
    # but verify if your IDE suggests 'partition_key' 
    # (though hash_key remains the standard in HCL for now).
    projection_type = "ALL"
  }

  # slug attribute 
  attribute {
    name = "slug"
    type = "S" # String
  }

  tags = {
    Name        = "${var.project_name}-main-table"
    Project     = var.project_name
    Environment = var.environment
  }
}

# --- Outputs for Application Logic ---

output "dynamodb_table_name" {
  description = "The name of the main DynamoDB table"
  value       = aws_dynamodb_table.blog_table.name
}

output "dynamodb_table_arn" {
  description = "The ARN of the main DynamoDB table"
  value       = aws_dynamodb_table.blog_table.arn
}
