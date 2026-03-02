data "archive_file" "image_optimizer_placeholder" {
  type        = "zip"
  output_path = "${path.module}/dummy_image_optimizer.zip"

  source {
    content  = "exports.handler = async (event) => { return { statusCode: 200, body: 'JS Placeholder' }; };"
    filename = "index.js" # 
  }
}


resource "aws_s3_object" "image_optimizer_place_holder_upload" {
  bucket = aws_s3_bucket.artifacts_storage.id
  key    = "image-optimizer-handler.zip"
  source = data.archive_file.image_optimizer_placeholder
  lifecycle {
    ignore_changes = [source, etag]
  }
}

resource "aws_lambda_function" "image_optimizer" {
  function_name = "${var.project_name}-image-optimizer"
  role          = aws_iam_role.optimizer_role.arn
  handler       = "index.handler" # Asegúrate de que tu build de GitHub Actions genere un index.js
  runtime       = "nodejs20.x"
  timeout       = 60   # Le subí un poco por si Sharp procesa imágenes pesadas
  memory_size   = 1024 # Sharp agradece mucho tener 1GB para ir rápido

  # IMPORTANTE: Aquí le decimos que busque en el bucket de Artifacts
  s3_bucket = aws_s3_bucket.artifacts_storage.id
  s3_key    = "image-optimizer-handler.zip"

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.blog_media.id
    }
  }

  # Esto permite que Terraform cree la Lambda aunque el zip aún sea el placeholder
  lifecycle {
    ignore_changes = [
      s3_key,
      source_code_hash,
      last_modified
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.optimizer_attach,
    aws_s3_object.image_optimizer_place_holder_upload
  ]
}


# Permiso explícito para que S3 llame a la Lambda
resource "aws_lambda_permission" "allow_s3_trigger" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_optimizer.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.blog_media.arn
}

# Configuración de la notificación
resource "aws_s3_bucket_notification" "on_upload" {
  bucket = aws_s3_bucket.blog_media.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_optimizer.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/" # MUY IMPORTANTE: Evita bucles infinitos
  }

  depends_on = [aws_lambda_permission.allow_s3_trigger]
}
