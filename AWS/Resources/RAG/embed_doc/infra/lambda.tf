# Layer
resource "aws_lambda_layer_version" "this" {
  s3_bucket = aws_s3_bucket.embed_doc_layer.bucket
  s3_key    = aws_s3_object.embed_doc_layer.key
  layer_name       = "embed-doc-lambda-layer"
  source_code_hash = filebase64sha256(data.archive_file.layer.output_path)
  compatible_runtimes = ["python3.10"]
  compatible_architectures = ["x86_64"]
}

# Lambda
resource "aws_lambda_function" "this" {
  filename      = data.archive_file.lambda.output_path
  function_name = "embed-doc-lambda"
  architectures = ["x86_64"]
  role          = aws_iam_role.this.arn
  handler       = "main.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.lambda.output_path)
  runtime = "python3.10"
  # すべての処理に6分必要のため、念のために10分に設定
  # メモリサイズは500MBくらいで十分
  timeout = 600
  memory_size = 512
  environment {
    variables = {
      S3BUCKET = aws_s3_bucket.embeddings.bucket,
      S3BUCKET_KEY = aws_s3_object.embeddings.key
    }
  }
  layers = [aws_lambda_layer_version.this.arn]

  depends_on = [aws_cloudwatch_log_group.this]
}

# Role
resource "aws_iam_role" "this" {
  name = "embed-doc-lambda-role"

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
  name        = "embed-doc-lambda-policy"
  description = "embed-doc-lambda policy"
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
        Action   = "s3:*",
        Resource = [
          aws_s3_bucket.embeddings.arn,
          "${aws_s3_bucket.embeddings.arn}/*"]
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
  name              = "/aws/lambda/embed-doc-lambda"
  retention_in_days = 30

  tags = {
    Name = "/aws/lambda/embed-doc-lambda"
  }
}
