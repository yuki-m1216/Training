# インテグレーション用のIAMロール
data "aws_iam_policy_document" "newrelic_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      // This is the unique identifier for New Relic account on AWS, there is no need to change this
      identifiers = [754728514883]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.NEW_RELIC_ACCOUNT_ID]
    }
  }
}

resource "aws_iam_role" "newrelic_aws_role" {
  name               = "NewRelicInfrastructure-Integrations"
  description        = "New Relic Cloud integration role"
  assume_role_policy = data.aws_iam_policy_document.newrelic_assume_policy.json
}

data "aws_iam_policy" "read_only_access" {
  arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "read_only_access_policy_attach" {
  role       = aws_iam_role.newrelic_aws_role.name
  policy_arn = data.aws_iam_policy.read_only_access.arn
}

# インテグレーション設定
resource "newrelic_cloud_aws_link_account" "newrelic_cloud_integration_push" {
  arn                    = aws_iam_role.newrelic_aws_role.arn
  metric_collection_mode = "PUSH"
  name                   = var.NEW_RELIC_ACCOUNT_NAME
}

# AWSからNew Relicへデータを送信する際に必要なIngest License Keysの作成
resource "newrelic_api_access_key" "newrelic_aws_access_key" {
  account_id  = var.NEW_RELIC_ACCOUNT_ID
  key_type    = "INGEST"
  ingest_type = "LICENSE"
  name        = "Ingest License key"
  notes       = "AWS Cloud Integrations Firehose Key"
}

# firehoseの設定
resource "aws_iam_role" "firehose_newrelic_role" {
  name               = "firehose_newrelic_role"
  assume_role_policy = data.aws_iam_policy_document.firehose_newrelic_assume_role_policy_document.json
}

resource "aws_iam_policy" "firehose_newrelic_policy" {
  name        = "firehose-newrelic-policy"
  description = "firehose-newrelic-policy"
  policy      = data.aws_iam_policy_document.firehose_newrelic_policy_document.json
}

resource "aws_iam_role_policy_attachment" "firehose_newrelic_attachment" {
  role       = aws_iam_role.firehose_newrelic_role.name
  policy_arn = aws_iam_policy.firehose_newrelic_policy.arn
}

resource "random_string" "s3-bucket-name" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "newrelic_aws_bucket" {
  bucket = "newrelic-aws-bucket-${random_string.s3-bucket-name.id}"
}

resource "aws_s3_bucket_ownership_controls" "newrelic_ownership_controls" {
  bucket = aws_s3_bucket.newrelic_aws_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_kinesis_firehose_delivery_stream" "newrelic_firehose_stream" {
  name        = "newrelic_firehose_stream"
  destination = "http_endpoint"

  http_endpoint_configuration {
    url                = "https://aws-api.newrelic.com/cloudwatch-metrics/v1"
    name               = "New Relic"
    access_key         = newrelic_api_access_key.newrelic_aws_access_key.key
    buffering_size     = 5
    buffering_interval = 900
    role_arn           = aws_iam_role.firehose_newrelic_role.arn
    s3_backup_mode     = "FailedDataOnly"

    s3_configuration {
      role_arn           = aws_iam_role.firehose_newrelic_role.arn
      bucket_arn         = aws_s3_bucket.newrelic_aws_bucket.arn
      buffering_size     = 10
      buffering_interval = 400
      compression_format = "GZIP"
    }

    request_configuration {
      content_encoding = "GZIP"
    }
  }
}

# CloudWatch メトリクスストリーム
resource "aws_iam_role" "metric_stream_to_firehose" {
  name               = "metric_stream_to_firehose_role"
  assume_role_policy = data.aws_iam_policy_document.metric_stream_to_firehose_assume_role_policy_document.json
}

resource "aws_iam_policy" "metric_stream_to_firehose_policy" {
  name        = "metric-stream-to-firehose-policy"
  description = "metric-stream-to-firehose-policy"
  policy      = data.aws_iam_policy_document.metric_stream_to_firehose_policy_document.json
}

resource "aws_iam_role_policy_attachment" "metric_stream_to_firehose_attachment" {
  role       = aws_iam_role.metric_stream_to_firehose.name
  policy_arn = aws_iam_policy.metric_stream_to_firehose_policy.arn
}

resource "aws_cloudwatch_metric_stream" "newrelic_metric_stream" {
  name          = "newrelic-metric-stream"
  role_arn      = aws_iam_role.metric_stream_to_firehose.arn
  firehose_arn  = aws_kinesis_firehose_delivery_stream.newrelic_firehose_stream.arn
  output_format = "opentelemetry0.7"
}
