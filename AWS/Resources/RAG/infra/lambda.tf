# Layer
resource "aws_lambda_layer_version" "this" {
  filename         = data.archive_file.layer.output_path
  layer_name       = "bedrock-embeddings-lambda-layer"
  source_code_hash = filebase64sha256(data.archive_file.layer.output_path)
}

# Lambda
resource "aws_lambda_function" "this" {
  filename      = data.archive_file.lambda.output_path
  function_name = "bedrock-embeddings-lambda"
  role          = aws_iam_role.this.arn
  handler       = "main.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.lambda.output_path)
  runtime = "python3.10"
  timeout = 30
  environment {
    variables = {
      OPENSEARCH_ENDPOINT = module.OpenSearchServerless.collection.collection_endpoint
    }
  }
  layers = [aws_lambda_layer_version.this.arn]

  depends_on = [aws_cloudwatch_log_group.this]
}

# Role
resource "aws_iam_role" "this" {
  name = "bedrock-embeddings-lambda-role"

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
  name        = "bedrock-embeddings-lambda-policy"
  description = "bedrock-embeddings-lambda policy"
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
      },
      {
        Effect   = "Allow",
        Action   = "bedrock:InvokeModel",
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "aoss:*",
        Resource = "*"
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
  name              = "/aws/lambda/bedrock-embeddings-lambda"
  retention_in_days = 30

  tags = {
    Name = "/aws/lambda/bedrock-embeddings-lambda"
  }
}
