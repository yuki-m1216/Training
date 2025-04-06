### embed-doc-lambda ###
# Layer
resource "aws_lambda_layer_version" "embed-doc" {
  s3_bucket                = aws_s3_bucket.embed_doc_layer.bucket
  s3_key                   = aws_s3_object.embed_doc_layer.key
  layer_name               = "embed-doc-lambda-layer"
  source_code_hash         = filebase64sha256(data.archive_file.embed_doc_layer.output_path)
  compatible_runtimes      = ["python3.10"]
  compatible_architectures = ["x86_64"]
}

# Lambda
resource "aws_lambda_function" "embed-doc" {
  filename         = data.archive_file.embed_doc_lambda.output_path
  function_name    = "embed-doc-lambda"
  architectures    = ["x86_64"]
  role             = aws_iam_role.embed-doc.arn
  handler          = "main.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.embed_doc_lambda.output_path)
  runtime          = "python3.10"
  # メモリサイズ2048ですべての処理に6分必要。
  # メモリサイズ1024ですべての処理に10分弱必要。
  # メモリサイズ512で10分だとタイムアウト。
  # メモリサイズ2048で実行した際、Max Memory Used: 651 MB。
  # メモリサイズは十分だがcpuパワーが必要なためと実行時間を考慮してメモリサイズ2048、タイムアウト600秒に設定。
  timeout     = 600
  memory_size = 2048
  environment {
    variables = {
      S3BUCKET     = aws_s3_bucket.embeddings.bucket,
      S3BUCKET_KEY = aws_s3_object.embeddings.key
    }
  }
  layers = [aws_lambda_layer_version.embed-doc.arn]

  depends_on = [aws_cloudwatch_log_group.embed-doc]
}

# Role
resource "aws_iam_role" "embed-doc" {
  name = "embed-doc-lambda-role"

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
resource "aws_iam_policy" "embed-doc" {
  name        = "embed-doc-lambda-policy"
  description = "embed-doc-lambda policy"
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
      {
        Effect = "Allow",
        Action = "s3:*",
        Resource = [
          aws_s3_bucket.embeddings.arn,
        "${aws_s3_bucket.embeddings.arn}/*"]
      }
    ]
  })
}

# Attachment
resource "aws_iam_role_policy_attachment" "embed-doc" {
  role       = aws_iam_role.embed-doc.name
  policy_arn = aws_iam_policy.embed-doc.arn
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "embed-doc" {
  name              = "/aws/lambda/embed-doc-lambda"
  retention_in_days = 30

  tags = {
    Name = "/aws/lambda/embed-doc-lambda"
  }
}

### vector-database-lambda ###
# Layer
resource "aws_lambda_layer_version" "vector_database" {
  s3_bucket                = aws_s3_bucket.vector_database.bucket
  s3_key                   = aws_s3_object.vector_database.key
  layer_name               = "vector-ingest-lambda-layer"
  source_code_hash         = filebase64sha256(data.archive_file.vector_database_layer.output_path)
  compatible_runtimes      = ["python3.10"]
  compatible_architectures = ["x86_64"]
}

# Lambda
resource "aws_lambda_function" "vector_database" {
  filename         = data.archive_file.vector_database_lambda.output_path
  function_name    = "vector-ingest-lambda"
  architectures    = ["x86_64"]
  role             = aws_iam_role.vector_database.arn
  handler          = "main.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.vector_database_lambda.output_path)
  runtime          = "python3.10"
  # すべての処理に6分必要のため、念のために10分に設定
  # メモリサイズは500MBくらいで十分
  timeout     = 600
  memory_size = 512
  environment {
    variables = {
      OPENSEARCH_ENDPOINT = module.OpenSearchServerless.collection.collection_endpoint,
      S3BUCKET            = aws_s3_bucket.embeddings.bucket,
      S3BUCKET_KEY        = "output/text-with-embedding.json"
    }
  }
  layers = [aws_lambda_layer_version.vector_database.arn]

  depends_on = [aws_cloudwatch_log_group.vector_database]
}

# Role
resource "aws_iam_role" "vector_database" {
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
resource "aws_iam_policy" "vector_database" {
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
          aws_s3_bucket.embeddings.arn,
          "${aws_s3_bucket.embeddings.arn}/*",
        ]
    }]
  })
}

# Attachment
resource "aws_iam_role_policy_attachment" "vector_database" {
  role       = aws_iam_role.vector_database.name
  policy_arn = aws_iam_policy.vector_database.arn
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "vector_database" {
  name              = "/aws/lambda/vector-ingest-lambda"
  retention_in_days = 30

  tags = {
    Name = "/aws/lambda/vector-ingest-lambda"
  }
}

### answer-user-query-lambda ###
# Layer
resource "aws_lambda_layer_version" "answer_user_query" {
  s3_bucket                = aws_s3_bucket.answer_user_query.bucket
  s3_key                   = aws_s3_object.answer_user_query.key
  layer_name               = "answer-user-query-lambda-layer"
  source_code_hash         = filebase64sha256(data.archive_file.answer_user_query_layer.output_path)
  compatible_runtimes      = ["python3.10"]
  compatible_architectures = ["x86_64"]
}

# Lambda
resource "aws_lambda_function" "answer_user_query" {
  filename         = data.archive_file.answer_user_query_lambda.output_path
  function_name    = "answer-user-query-lambda"
  architectures    = ["x86_64"]
  role             = aws_iam_role.opensearch_access_role.arn
  handler          = "main.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.answer_user_query_lambda.output_path)
  runtime          = "python3.10"
  timeout          = 600
  memory_size      = 512
  environment {
    variables = {
      OPENSEARCH_ENDPOINT = module.OpenSearchServerless.collection.collection_endpoint,
    }
  }
  layers = [aws_lambda_layer_version.answer_user_query.arn]

  depends_on = [aws_cloudwatch_log_group.answer_user_query]
}

# Policy
resource "aws_iam_policy" "answer_user_query" {
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
resource "aws_iam_role_policy_attachment" "answer_user_query" {
  role       = aws_iam_role.opensearch_access_role.id
  policy_arn = aws_iam_policy.answer_user_query.arn
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "answer_user_query" {
  name              = "/aws/lambda/answer-user-query-lambda"
  retention_in_days = 30

  tags = {
    Name = "/aws/lambda/answer-user-query-lambda"
  }
}
