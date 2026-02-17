data "archive_file" "auth_placeholder" {
  type        = "zip"
  output_path = "${path.module}/dummy_auth.zip"

  source {
    content  = "exports.handler= async()=> {return {statusCode:200, body:'Auth Placeholder'}};"
    filename = "index.js"
  }
}
resource "aws_s3_object" "auth_placeholder_upload" {
  bucket = aws_s3_bucket.artifacts_storage.id
  key    = "auth-handler.zip"
  source = data.archive_file.auth_placeholder.output_path

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

  s3_bucket = "blog-website-artifacts"
  s3_key    = "auth-handler.zip"


  s3_object_version = aws_s3_object.auth_placeholder_upload.version_id


  depends_on = [aws_s3_object.auth_placeholder_upload]

  lifecycle {
    ignore_changes = [
      s3_key,
      source_code_hash,
      last_modified,
      s3_object_version
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
