data "archive_file" "posts_placeholder" {
  type        = "zip"
  output_path = "${path.module}/dummy_posts.zip"

  source {
    content  = "def lambda_handler(event,context):\n return { 'statusCode':200, 'body': 'Python Posts Crud'}"
    filename = "lambda_function.py"
  }
}

resource "aws_s3_object" "posts_place_holder_upload" {
  bucket = aws_s3_bucket.artifacts_storage.id
  key    = "posts-handler.zip"
  source = data.archive_file.posts_placeholder.output_path

  lifecycle {
    ignore_changes = [source, etag]
  }
}

resource "aws_lambda_function" "posts_handler" {
  function_name = "${var.project_name}-posts-handler"
  role          = aws_iam_role.posts_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  memory_size   = 128

  # Enable versioning so aliases like 'live' can point to specific versions
  publish = true

  s3_bucket = aws_s3_bucket.artifacts_storage.id
  s3_key    = "posts-handler.zip"

  depends_on = [
    aws_iam_role.posts_lambda_role,
    aws_iam_role_policy.posts_lambda_policy,
    aws_s3_object.posts_place_holder_upload
  ]

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.blog_table.name
      REGION     = var.aws_region
      SLUG_INDEX = "SlugIndex"
    }
  }
  lifecycle {
    # We ignore changes because GitHub Actions (Orange Pi) handles the real deployments
    ignore_changes = [s3_key, source_code_hash, s3_object_version, last_modified]
  }
}

# Solo crea la Layer, no la asignes a la Lambda aquí
resource "aws_lambda_layer_version" "ulid_layer" {
  layer_name          = "ulid-layer"
  filename            = "ulid_layer.zip" 
  compatible_runtimes = ["python3.12"]
}

# Opcional: Guarda el ARN en un parámetro para que el otro repo lo lea
resource "aws_ssm_parameter" "ulid_layer_arn" {
  name  = "/blog/layers/ulid_arn"
  type  = "String"
  value = aws_lambda_layer_version.ulid_layer.arn
}