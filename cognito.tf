# --- Cognito User Pool Configuration ---

resource "aws_cognito_user_pool" "pool" {
  name = "${var.project_name}-user-pool"

  # Standard user profile attributes
  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "name"
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 2048
    }
  }

  # Account recovery settings
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Login identifiers
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Security policy for passwords
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_symbols   = true
    require_numbers   = true
  }

  # Email verification template
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message        = "Your confirmation number is {####}"
    email_subject        = " ${var.project_name} account verification"
  }

  # Lambda trigger to sync data to DynamoDB after user confirmation
  lambda_config {
    post_confirmation = aws_lambda_function.auth_handler.arn
  }
}

# --- Cognito User Pool Client ---

resource "aws_cognito_user_pool_client" "client" {
  name         = "${var.project_name}-client"
  user_pool_id = aws_cognito_user_pool.pool.id

  # Public client: Secret is disabled for frontend/static calls
  generate_secret               = false
  prevent_user_existence_errors = "ENABLED"

  # Authentication flows for serverless web applications
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_CUSTOM_AUTH"
  ]
}

# --- Custom Domain for Cognito ---

resource "aws_cognito_user_pool_domain" "auth_domain" {
  domain       = "${var.project_name}-auth"
  user_pool_id = aws_cognito_user_pool.pool.id
}

# --- Outputs for Next.js Environment Variables ---

output "cognito_user_pool_id" {
  description = "The ID of the User Pool"
  value       = aws_cognito_user_pool.pool.id
}

output "cognito_client_id" {
  description = "The ID of the User Pool Client"
  value       = aws_cognito_user_pool_client.client.id
}

output "cognito_domain" {
  description = "The custom domain for Cognito authentication"
  value       = "${aws_cognito_user_pool_domain.auth_domain.domain}.auth.${var.aws_region}.amazoncognito.com"
}
