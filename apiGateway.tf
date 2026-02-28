# --- API Gateway HTTP Definition ---
resource "aws_apigatewayv2_api" "blog_api" {
  name          = "${var.project_name}-blog-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PATCH", "DELETE", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
    max_age       = 300
  }
}

# --- API Stages ---
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.blog_api.id
  name        = "$default" # Ojo: asegúrate de que sea el nombre correcto que usas
  auto_deploy = true

  # Forzamos límites altos para limpiar el bloqueo previo
  default_route_settings {
    throttling_burst_limit = 500
    throttling_rate_limit  = 1000
  }

}

# --- Authorizer ---
resource "aws_apigatewayv2_authorizer" "cognito_auth" {
  api_id           = aws_apigatewayv2_api.blog_api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-authorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.client.id]
    issuer   = "https://${aws_cognito_user_pool.pool.endpoint}"
  }
}

# --- Integrations ---
resource "aws_apigatewayv2_integration" "auth_integration" {
  api_id                 = aws_apigatewayv2_api.blog_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.auth_handler.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "posts_integration" {
  api_id                 = aws_apigatewayv2_api.blog_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = "${aws_lambda_function.posts_handler.arn}:live"
  payload_format_version = "2.0"
}



# --- ROUTES ---

# 1. PUBLIC ROUTES (No Auth)
resource "aws_apigatewayv2_route" "signup" {
  api_id    = aws_apigatewayv2_api.blog_api.id
  route_key = "POST /signup"
  target    = "integrations/${aws_apigatewayv2_integration.auth_integration.id}"
}

resource "aws_apigatewayv2_route" "posts_get_all" {
  api_id    = aws_apigatewayv2_api.blog_api.id
  route_key = "GET /posts"
  target    = "integrations/${aws_apigatewayv2_integration.posts_integration.id}"
}

resource "aws_apigatewayv2_route" "posts_get_one" {
  api_id    = aws_apigatewayv2_api.blog_api.id
  route_key = "GET /posts/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.posts_integration.id}"
}

# 2. SECURE ROUTES (Require JWT)
# Create
resource "aws_apigatewayv2_route" "posts_create" {
  api_id             = aws_apigatewayv2_api.blog_api.id
  route_key          = "POST /posts"
  target             = "integrations/${aws_apigatewayv2_integration.posts_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

# Update (PATCH)
resource "aws_apigatewayv2_route" "posts_patch" {
  api_id             = aws_apigatewayv2_api.blog_api.id
  route_key          = "PATCH /posts/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.posts_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

# Delete (DELETE)
resource "aws_apigatewayv2_route" "posts_delete" {
  api_id             = aws_apigatewayv2_api.blog_api.id
  route_key          = "DELETE /posts/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.posts_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

# --- Permissions ---
resource "aws_lambda_permission" "api_gw_posts" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.posts_handler.function_name
  principal     = "apigateway.amazonaws.com"
  qualifier     = "live"
  source_arn    = "${aws_apigatewayv2_api.blog_api.execution_arn}/*/*"
}


#-- image integration 

resource "aws_apigatewayv2_integration" "image_integration" {
  api_id                 = aws_apigatewayv2_api.blog_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = "${aws_lambda_function.image_handler.arn}:live"
  payload_format_version = "2.0"
}

#-- public Route --#

resource "aws_apigatewayv2_route" "image_presigned" {  
  api_id             = aws_apigatewayv2_api.blog_api.id
  route_key          = "POST /files/presigned"
  target             = "integrations/${aws_apigatewayv2_integration.image_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_lambda_permission" "api_gw_image" {
  statement_id  = "AllowExecutionFromAPIGatewayImage"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_handler.function_name
  principal     = "apigateway.amazonaws.com"
  qualifier     = "live" # Importante porque usas :live en la integración
  source_arn    = "${aws_apigatewayv2_api.blog_api.execution_arn}/*/*"
}

resource "aws_lambda_alias" "image_handler_live" {
  name             = "live"
  description      = "Alias para el despliegue desde GitHub Actions"
  function_name    = aws_lambda_function.image_handler.function_name
  function_version = aws_lambda_function.image_handler.version
  
  lifecycle {
    ignore_changes = [function_version] # Para que GH Actions lo maneje
  }
}