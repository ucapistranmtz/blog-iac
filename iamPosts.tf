resource "aws_iam_role" "posts_lambda_role" {
  name = "${var.project_name}-posts-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "posts_lambda_policy" {
  name = "posts-lambda-permissions"
  role = aws_iam_role.posts_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["dynamodb.PutItem", "dynamodb.GetItem", "dynamodb.UpdateItem", "dynamodb.Query", "dynamodb.Scan"]
        Resource = [
          aws_dynamodb_table.blog_table.arn,
          "${aws.dynamodb_table.blog_table.arn}/index/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:Create:LogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })

}
