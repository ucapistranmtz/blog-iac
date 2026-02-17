
resource "aws_s3_object" "auth_placeholder_upload" {
  bucket = aws_s3_bucket.artifacts_storage.id
  key    = "auth-handler.zip"
  source = data.archive_file.auth_placeholder.output_path

  # Solo lo sube si no existe; luego GitHub Actions se encarga
  lifecycle {
    ignore_changes = [source, etag]
  }
}

resource "aws_lambda_function" "auth_handler" {
  function_name = "${var.project_name}-auth-handler"
  role          = aws_iam_role.auth_lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  memory_size   = 512

  s3_bucket = aws_s3_bucket.artifacts_storage.id
  s3_key    = aws_s3_object.auth_placeholder_upload.key

  lifecycle {
    ignore_changes = [
      s3_key,
      source_code_hash,
      last_modified,
    ]
  }

  environment {
    variables = {
      DATABASE_URL         = var.database_url
      BETTER_AUTH_SECRET   = var.better_auth_secret
      COGNITO_USER_POOL_ID = aws_cognito_user_pool.pool.id
      COGNITO_CLIENT_ID    = aws_cognito_user_pool_client.client.id
    }
  }
}
