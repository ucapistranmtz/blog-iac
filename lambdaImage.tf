data "archive_file" "image_placeholder" {
  type        = "zip"
  output_path = "${path.module}/dummy_image.zip"

  source {
    content  = "exports.handler = async (event) => { return { statusCode: 200, body: 'JS Placeholder' }; };"
    filename = "index.js" # <-- Debe ser .js
  }
}


resource "aws_s3_object" "image_place_holder_upload" {
  bucket = aws_s3_bucket.artifacts_storage.id
  key = "image-handler.zip"  
  source = data.archive_file.image_placeholder.output_path  
  lifecycle {
    ignore_changes = [source,etag]
  }
}


resource "aws_lambda_function" "image_handler" {
  function_name = "${var.project_name}-image-handler"
  role = aws_iam_role.auth_lambda_role.arn
  handler = "index.handler" 
  runtime = "nodejs22.x"
  memory_size = 128

  publish = true
  s3_bucket =  aws_s3_bucket.artifacts_storage.id
  s3_key = "image-handler.zip"

  environment {
    variables = {
      MEDIA_BUCKET_NAME = aws_s3_bucket.blog_media.id  # El nombre de tu bucket de imágenes
      AWS_REGION        = var.aws_region              # Tu región (ej. us-east-1)
    }
  }
  

  depends_on = [ 
                aws_iam_role.auth_lambda_role,
                aws_iam_role_policy.posts_lambda_policy,
                aws_s3_object.image_place_holder_upload
               ]

  
  lifecycle {
    ignore_changes = [s3_key,source_code_hash,s3_object_version,last_modified ]
  }


}