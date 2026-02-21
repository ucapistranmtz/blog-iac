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
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 10
    throttling_rate_limit  = 5
  }
}

# --- Integrations ---

# Auth Lambda Integration
resource "aws_apigatewayv2_integration" "auth_integration" {
  api_id                 = aws_apigatewayv2_api.blog_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.auth_handler.invoke_arn
  payload_format_version = "2.0"
}

# --- Posts Lambda Integration ---

resource "aws_apigatewayv2_integration" "posts_integration" {
  api_id           = aws_apigatewayv2_api.blog_api.id
  integration_type = "AWS_PROXY"

  # CORRECT FORMAT for HTTP API + Alias: Function ARN + :alias
  integration_uri = "${aws_lambda_function.posts_handler.arn}:live"

  payload_format_version = "2.0"
  connection_type        = "INTERNET"
}

# --- Routes ---

resource "aws_apigatewayv2_route" "signup" {
  api_id    = aws_apigatewayv2_api.blog_api.id
  route_key = "POST /signup"
  target    = "integrations/${aws_apigatewayv2_integration.auth_integration.id}"
}

resource "aws_apigatewayv2_route" "posts_root" {
  api_id    = aws_apigatewayv2_api.blog_api.id
  route_key = "ANY /posts"
  target    = "integrations/${aws_apigatewayv2_integration.posts_integration.id}"
}

resource "aws_apigatewayv2_route" "posts_item" {
  api_id    = aws_apigatewayv2_api.blog_api.id
  route_key = "ANY /posts/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.posts_integration.id}"
}

# --- Permissions ---

resource "aws_lambda_permission" "api_gw_auth" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.blog_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_posts" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.posts_handler.function_name
  principal     = "apigateway.amazonaws.com"

  # This qualifier must match the end of the integration_uri
  qualifier  = "live"
  source_arn = "${aws_apigatewayv2_api.blog_api.execution_arn}/*/*"
}

# --- Outputs ---

output "api_gateway_url" {
  description = "The primary URL for the Blog API Gateway"
  value       = aws_apigatewayv2_api.blog_api.api_endpoint
}

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

# Esta ruta sigue siendo pública (Read-only)
resource "aws_apigatewayv2_route" "posts_get" {
  api_id    = aws_apigatewayv2_api.blog_api.id
  route_key = "GET /posts"
  target    = "integrations/${aws_apigatewayv2_integration.posts_integration.id}"
}

# Esta ruta requiere un Token JWT válido (Write/Edit)
resource "aws_apigatewayv2_route" "posts_secure" {
  api_id    = aws_apigatewayv2_api.blog_api.id
  route_key = "POST /posts"
  target    = "integrations/${aws_apigatewayv2_integration.posts_integration.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}
