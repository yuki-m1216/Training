# Layer
resource "aws_lambda_layer_version" "this" {
  s3_bucket                = aws_s3_bucket.this.bucket
  s3_key                   = aws_s3_object.this.key
  layer_name               = "vector-ingest-lambda-layer"
  source_code_hash         = filebase64sha256(data.archive_file.layer.output_path)
  compatible_runtimes      = ["python3.10"]
  compatible_architectures = ["x86_64"]
}

# Lambda
resource "aws_lambda_function" "this" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "vector-ingest-lambda"
  architectures    = ["x86_64"]
  role             = aws_iam_role.this.arn
  handler          = "main.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.lambda.output_path)
  runtime          = "python3.10"
  # すべての処理に6分必要のため、念のために10分に設定
  # メモリサイズは500MBくらいで十分
  timeout     = 600
  memory_size = 512
  environment {
    variables = {
      OPENSEARCH_ENDPOINT = module.OpenSearchServerless.collection.collection_endpoint,
      S3BUCKET            = data.terraform_remote_state.embed_doc.outputs.bedrock_embeddings_files_bucket_bucket,
      S3BUCKET_KEY        = "output/text-with-embedding.json"
    }
  }
  layers = [aws_lambda_layer_version.this.arn]

  depends_on = [aws_cloudwatch_log_group.this]
}

# Role
resource "aws_iam_role" "this" {
  name = "vector-ingest-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Policy
resource "aws_iam_policy" "this" {
  name        = "vector-ingest-lambda-policy"
  description = "vector-ingest-lambda policy"
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
        Action   = "aoss:*",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = "s3:*",
        Resource = [
          data.terraform_remote_state.embed_doc.outputs.bedrock_embeddings_files_bucket_arn,
          "${data.terraform_remote_state.embed_doc.outputs.bedrock_embeddings_files_bucket_arn}/*"
        ]
    }]
  })
}

# Attachment
resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/vector-ingest-lambda"
  retention_in_days = 30

  tags = {
    Name = "/aws/lambda/vector-ingest-lambda"
  }
}
