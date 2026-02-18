# --- API Gateway HTTP Definition ---

resource "aws_apigatewayv2_api" "blog_api" {
  name          = "${var.project_name}-blog-api"
  protocol_type = "HTTP"

  cors_configuration {
    # Replace '*' with your specific S3/CloudFront URL for production security
    allow_origins = ["*"]
    allow_methods = ["POST", "GET", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
    max_age       = 300
  }
}

# --- API Stages ---

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.blog_api.id
  name        = "$default"
  auto_deploy = true

  # Basic throttling to stay within free tier limits
  default_route_settings {
    throttling_burst_limit = 10
    throttling_rate_limit  = 5
  }
}

# --- Routes & Integrations ---

# Registration Route
resource "aws_apigatewayv2_route" "signup" {
  api_id    = aws_apigatewayv2_api.blog_api.id
  route_key = "POST /signup"
  target    = "integrations/${aws_apigatewayv2_integration.auth_integration.id}"
}

# Integration with the Auth Lambda Function
resource "aws_apigatewayv2_integration" "auth_integration" {
  api_id                 = aws_apigatewayv2_api.blog_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.auth_handler.invoke_arn
  payload_format_version = "2.0"
}

# --- Outputs ---

output "api_gateway_url" {
  description = "The primary URL for the Blog API Gateway"
  value       = aws_apigatewayv2_api.blog_api.api_endpoint
}
