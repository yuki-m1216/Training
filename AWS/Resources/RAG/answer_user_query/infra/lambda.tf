# Layer
resource "aws_lambda_layer_version" "this" {
  s3_bucket                = aws_s3_bucket.this.bucket
  s3_key                   = aws_s3_object.this.key
  layer_name               = "answer-user-query-lambda-layer"
  source_code_hash         = filebase64sha256(data.archive_file.layer.output_path)
  compatible_runtimes      = ["python3.10"]
  compatible_architectures = ["x86_64"]
}

# Lambda
resource "aws_lambda_function" "this" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "answer-user-query-lambda"
  architectures    = ["x86_64"]
  role             = data.terraform_remote_state.vector_database.outputs.opensearch_access_role_arn
  handler          = "main.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.lambda.output_path)
  runtime          = "python3.10"
  timeout     = 600
  memory_size = 512
  environment {
    variables = {
      OPENSEARCH_ENDPOINT = data.terraform_remote_state.vector_database.outputs.collection_endpoint,
    }
  }
  layers = [aws_lambda_layer_version.this.arn]

  depends_on = [aws_cloudwatch_log_group.this]
}

# Policy
resource "aws_iam_policy" "this" {
  name        = "answer-user-query-lambda-policy"
  description = "answer-user-query-lambda policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
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
    ]
  })
}

# Attachment
resource "aws_iam_role_policy_attachment" "this" {
  role       = data.terraform_remote_state.vector_database.outputs.opensearch_access_role_id
  policy_arn = aws_iam_policy.this.arn
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/answer-user-query-lambda"
  retention_in_days = 30

  tags = {
    Name = "/aws/lambda/answer-user-query-lambda"
  }
}
