
data "archive_file" "auth_placeholder" {
  type        = "zip"
  output_path = "${path.module}/dummy_auth.zip"

  source {
    content  = "exports.handler= async()=> {return  {statusCode:200, body:'Auth Placeholder'}};"
    filename = "index.js"
  }

}

resource "aws_lambda_function" "auth_handler" {
  function_name = "${var.project_name}-auth-handler"
  role          = aws_iam_role.auth_lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  memory_size   = 512

  filename         = data.archive_file.auth_placeholder.output_path
  source_code_hash = data.archive_file.auth_placeholder.output_base64sha256

  lifecycle {
    ignore_changes = [
      filename,
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
