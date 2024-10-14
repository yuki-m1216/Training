resource "newrelic_api_access_key" "newrelic_aws_for_cloudwatch_logs_access_key" {
  account_id  = var.NEW_RELIC_ACCOUNT_ID
  key_type    = "INGEST"
  ingest_type = "LICENSE"
  name        = "Ingest License key for AWS CloudWatch Logs"
  notes       = "AWS CloudWatch Logs Firehose Key"
}

resource "aws_iam_role" "firehose_newrelic_for_cloudwatch_logs_role" {
  name = "firehose-newrelic-for-cloudwatch-logs-role"
  assume_role_policy = data.aws_iam_policy_document.firehose_newrelic_assume_role_for_cloudwatch_logs_policy_document.json
}

resource "aws_iam_policy" "firehose_newrelic_for_cloudwatch_logs_policy" {
  name        = "firehose-newrelic-for-cloudwatch-logs-policy"
  description = "firehose-newrelic-for-cloudwatch-logs-policy"
  policy      = data.aws_iam_policy_document.firehose_newrelic_for_cloudwatch_logs_policy_document.json
}

resource "aws_iam_role_policy_attachment" "firehose_newrelic_for_cloudwatch_logs_attachment" {
  role       = aws_iam_role.firehose_newrelic_for_cloudwatch_logs_role.name
  policy_arn = aws_iam_policy.firehose_newrelic_for_cloudwatch_logs_policy.arn
}

resource "random_string" "s3_bucket_name_firehose_newrelic_for_cloudwatch_logs" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "newrelic_for_cloudwatch_logs_bucket" {
  bucket = "newrelic-for-cloudwatch-logs-bucket-${random_string.s3_bucket_name_firehose_newrelic_for_cloudwatch_logs.id}"
}

resource "aws_s3_bucket_ownership_controls" "newrelic_newrelic_for_cloudwatch_logs_ownership_controls" {
  bucket = aws_s3_bucket.newrelic_for_cloudwatch_logs_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_kinesis_firehose_delivery_stream" "newrelic_firehose_stream_for_cloudwatch_logs" {
  name        = "newrelic_firehose_stream_for_cloudwatch_logs"
  destination = "http_endpoint"

  http_endpoint_configuration {
    url            = "https://aws-api.newrelic.com/firehose/v1"
    name           = "New Relic"
    access_key     = newrelic_api_access_key.newrelic_aws_for_cloudwatch_logs_access_key.key
    role_arn       = aws_iam_role.firehose_newrelic_for_cloudwatch_logs_role.arn
    s3_backup_mode = "FailedDataOnly"

    # These default settings are not appropriate for log management in New Relic. We strongly advise to use 1 MiB as the Buffer size and activate GZIP body compression.
    buffering_size     = 1
    buffering_interval = 60
    request_configuration {
      content_encoding = "GZIP"
    }


    s3_configuration {
      role_arn           = aws_iam_role.firehose_newrelic_for_cloudwatch_logs_role.arn
      bucket_arn         = aws_s3_bucket.newrelic_for_cloudwatch_logs_bucket.arn
      buffering_size     = 10
      buffering_interval = 300
      compression_format = "GZIP"
    }
  }
}

resource "aws_cloudwatch_log_subscription_filter" "newrelic_firehose_stream_for_cloudwatch_logs_filter" {
  for_each = var.subscription_filters

  name            = each.key
  role_arn        = aws_iam_role.newrelic_firehose_stream_for_cloudwatch_logs_filter_role.arn
  log_group_name  = each.value.log_group_name
  filter_pattern  = each.value.filter_pattern
  destination_arn = aws_kinesis_firehose_delivery_stream.newrelic_firehose_stream_for_cloudwatch_logs.arn
}

resource "aws_iam_role" "newrelic_firehose_stream_for_cloudwatch_logs_filter_role" {
  name = "firehose-newrelic-for-cloudwatch-logs-subscription-filter-role"
  assume_role_policy = data.newrelic_firehose_stream_assume_role_for_cloudwatch_logs_filter_policy_document.json
}

resource "aws_iam_policy" "firehose_newrelic_for_cloudwatch_logs_filter_policy" {
  name        = "firehose-newrelic-for-cloudwatch-logs-subscription-filter-policy"
  description = "firehose-newrelic-for-cloudwatch-logs-subscription-filter-policy"
  policy      = data.newrelic_firehose_stream_for_cloudwatch_logs_filter_policy_document.json
}

resource "aws_iam_role_policy_attachment" "firehose_newrelic_for_cloudwatch_logs_attachment" {
  role       = aws_iam_role.newrelic_firehose_stream_for_cloudwatch_logs_filter_role.name
  policy_arn = aws_iam_policy.firehose_newrelic_for_cloudwatch_logs_filter_policy.arn
}