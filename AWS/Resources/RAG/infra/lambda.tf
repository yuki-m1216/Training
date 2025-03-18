# Layer
resource "aws_lambda_layer_version" "this" {
  filename         = data.archive_file.layer.output_path
  layer_name       = "my-layer"
  source_code_hash = filebase64sha256(data.archive_file.layer.output_path)
}

# Lambda
resource "aws_lambda_function" "this" {
  filename      = data.archive_file.lambda.output_path
  function_name = "my-lambda"
  role          = aws_iam_role.this.arn
  handler       = "src/scraping.lambda_handler"

  source_code_hash = filebase64sha256(data.archive_file.lambda.output_path)
  runtime = "python3.10"

  depends_on = [aws_cloudwatch_log_group.this]
}

# Role
resource "aws_iam_role" "this" {
  name = "my-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action    = "sts:AssumeRole" 
      }
    ]
  })
}

# Policy
resource "aws_iam_policy" "this" {
  name        = "my-policy"
  description = "My policy"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attachment
resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/my-lambda"
  retention_in_days = 30

  tags = {
    Name = "/aws/lambda/my-lambda"
  }
}
