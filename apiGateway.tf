# --- API Gateway HTTP Definition ---

resource "aws_apigatewayv2_api" "blog_api" {
  name          = "${var.project_name}-blog-api"
  protocol_type = "HTTP"

  cors_configuration {
    # Replace '*' with your specific CloudFront/Domain URL in production
    allow_origins = ["*"]
    # Added PATCH and DELETE for our service.py logic (Update and Soft Delete)
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

  # Throttling to protect your Lambda and DynamoDB limits
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

# Posts Lambda Integration (Modular service.py)
resource "aws_apigatewayv2_integration" "posts_integration" {
  api_id           = aws_apigatewayv2_api.blog_api.id
  integration_type = "AWS_PROXY"

  # Crucial: Use invoke_arn with the 'live' alias pointer
  integration_uri = "${aws_lambda_function.posts_handler.invoke_arn}:live"

  payload_format_version = "2.0"
  connection_type        = "INTERNET"
}

# --- Routes ---

# Auth: Registration
resource "aws_apigatewayv2_route" "signup" {
  api_id    = aws_apigatewayv2_api.blog_api.id
  route_key = "POST /signup"
  target    = "integrations/${aws_apigatewayv2_integration.auth_integration.id}"
}

# Posts: Root (GET all, POST new)
resource "aws_apigatewayv2_route" "posts_root" {
  api_id    = aws_apigatewayv2_api.blog_api.id
  route_key = "ANY /posts"
  target    = "integrations/${aws_apigatewayv2_integration.posts_integration.id}"
}

# Posts: Item (GET one, PATCH update, DELETE soft-delete)
resource "aws_apigatewayv2_route" "posts_item" {
  api_id    = aws_apigatewayv2_api.blog_api.id
  route_key = "ANY /posts/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.posts_integration.id}"
}

# --- Permissions ---

# Permission for Auth Lambda
resource "aws_lambda_permission" "api_gw_auth" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.blog_api.execution_arn}/*/*"
}

# Permission for Posts Lambda (Specific to 'live' alias)
resource "aws_lambda_permission" "api_gw_posts" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.posts_handler.function_name
  principal     = "apigateway.amazonaws.com"

  # Qualifier is mandatory when the integration uri includes an alias
  qualifier  = "live"
  source_arn = "${aws_apigatewayv2_api.blog_api.execution_arn}/*/*"
}

# --- Outputs ---

output "api_gateway_url" {
  description = "The primary URL for the Blog API Gateway"
  value       = aws_apigatewayv2_api.blog_api.api_endpoint
}
