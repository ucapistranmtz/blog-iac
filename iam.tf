# --- Lambda Execution Role ---

resource "aws_iam_role" "auth_lambda_role" {
  name = "${var.project_name}-auth-lambda-role"

  # Trust policy allowing Lambda service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# --- CloudWatch Logs Policy Attachment ---

# Provides basic permissions to upload logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.auth_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- Application Specific Permissions ---

# Custom policy for Cognito and DynamoDB access
resource "aws_iam_policy" "auth_app_access" {
  name        = "${var.project_name}-auth-app-access"
  description = "Permissions for Auth Lambda to manage Cognito users and DynamoDB records"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Permissions for Cognito User Management
        Effect = "Allow"
        Action = [
          "cognito-idp:AdminGetUser",
          "cognito-idp:AdminCreateUser",
          "cognito-idp:AdminUpdateUserAttributes",
          "cognito-idp:AdminSetUserPassword",
          "cognito-idp:SignUp",
          "cognito-idp:AdminConfirmSignUp"
        ]
        Resource = aws_cognito_user_pool.pool.arn
      },
      {
        # Permissions for DynamoDB Data Operations
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.blog_table.arn,
          "${aws_dynamodb_table.blog_table.arn}/index/*"
        ]
      }
    ]
  })
}

# Attachment of the custom policy to the Lambda role
resource "aws_iam_role_policy_attachment" "attach_auth_policy" {
  role       = aws_iam_role.auth_lambda_role.name
  policy_arn = aws_iam_policy.auth_app_access.arn
}

 resource "aws_iam_role_policy" "image_s3_policy" {
  name = "image-upload-policy"
  role = aws_iam_role.auth_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:PutObject"]
        Effect   = "Allow"
         Resource = "${aws_s3_bucket.blog_media.arn}/blog/images/*"
      }
    ]
  })
}