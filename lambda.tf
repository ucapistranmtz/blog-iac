# --- Lambda Package Preparation ---

# Create a dummy zip file for the initial terraform apply
# This prevents errors when the function is created before real code exists
data "archive_file" "auth_placeholder" {
  type        = "zip"
  output_path = "${path.module}/dummy_auth.zip"

  source {
    content  = "exports.handler = async () => { return { statusCode: 200, body: 'Auth Placeholder' } };"
    filename = "index.js"
  }
}

# Upload the dummy zip to the centralized artifacts bucket
resource "aws_s3_object" "auth_placeholder_upload" {
  bucket = aws_s3_bucket.artifacts_storage.id
  key    = "auth-handler.zip"
  source = data.archive_file.auth_placeholder.output_path

  # Prevent Terraform from overwriting real code uploaded by your CI/CD pipeline
  lifecycle {
    ignore_changes = [source, etag]
  }
}

# --- Lambda Function Definition ---

resource "aws_lambda_function" "auth_handler" {
  function_name = "${var.project_name}-auth-handler"
  role          = aws_iam_role.auth_lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs22.x" # Using latest Node.js 22
  memory_size   = 256

  # Location of the code in S3
  s3_bucket = aws_s3_bucket.artifacts_storage.id
  s3_key    = "auth-handler.zip"

  # Initial version management
  s3_object_version = aws_s3_object.auth_placeholder_upload.version_id

  depends_on = [aws_s3_object.auth_placeholder_upload]

  # Essential for serverless deployments: ignore code changes to allow independent updates
  lifecycle {
    ignore_changes = [
      s3_key,
      source_code_hash,

      s3_object_version
    ]
  }

  # Environment variables for application logic
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.blog_table.name
      REGION     = var.aws_region
    }
  }
}

# --- Trigger Permissions ---

# Allow Cognito to invoke the Lambda for Post-Confirmation triggers
resource "aws_lambda_permission" "cognito_trigger_permission" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_handler.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.pool.arn
}
