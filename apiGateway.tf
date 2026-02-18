resource "aws_apigatewayv2_api" "blog_api" {
  name          = "${var.project_name}-blog-api"
  protocol_type = "HTTP"

  disable_execute_api_endpoint = false

  cors_configuration {
    allow_origins     = ["http://localhost:3000"]
    allow_methods     = ["POST", "GET", "OPTIONS"]
    allow_headers     = ["content-type", "authorization", "cookie"]
    allow_credentials = true
    max_age           = 300
  }
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.blog_api.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 10
    throttling_rate_limit  = 5
  }
}


resource "aws_apigatewayv2_integration" "lambda_blog_int" {
  api_id           = aws_apigatewayv2_api.blog_api.id
  integration_type = "AWS_PROXY"

  # CAMBIO AQUÍ: Usa .arn en lugar de .invoke_arn
  integration_uri        = aws_lambda_function.auth_handler.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "auth_route" {
  api_id    = aws_apigatewayv2_api.blog_api.id
  route_key = "ANY /api/auth/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_blog_int.id}"

}


resource "aws_lambda_permission" "api_gtw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_handler.function_name
  principal     = "apigateway.amazonaws.com"

  # IMPORTANTE: El permiso debe ser para el Alias específico
  source_arn = "${aws_apigatewayv2_api.blog_api.execution_arn}/*/*"
  #qualifier  = "live"
}

output "api_gateway_url" {
  description = "La URL principal de tu API para el Blog"
  value       = aws_apigatewayv2_api.blog_api.api_endpoint
}
