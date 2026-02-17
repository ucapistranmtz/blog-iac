resource "aws_apigatewayv2_api" "blog_api" {
  name          = "${var.project_name}-blog-api"
  protocol_type = "HTTP"

  disable_execute_api_endpoint = false

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "GET"]
    allow_headers = ["content-type", "authorization"]
    max_age       = 30
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
  # Agregamos :live al final para usar el alias estable
  integration_uri        = "${aws_lambda_function.auth_handler.arn}:live"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "auth_route" {
  api_id    = aws_apigatewayv2_api.blog_api.id
  route_key = "ANY /api/auth/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_blog_int.id}"

}


#permisions 

resource "aws_lambda_permission" "api_gtw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.blog_api.execution_arn}/*/*"
  qualifier     = "live" # <--- Esto es clave
}


output "api_gateway_url" {
  description = "La URL principal de tu API para el Blog"
  value       = aws_apigatewayv2_api.blog_api.api_endpoint
}
