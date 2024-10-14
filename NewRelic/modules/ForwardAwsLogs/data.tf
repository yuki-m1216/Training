data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "firehose_newrelic_assume_role_for_cloudwatch_logs_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "firehose_newrelic_for_cloudwatch_logs_policy_document" {
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]
    resources = [
      aws_s3_bucket.newrelic_for_cloudwatch_logs_bucket.arn,
      "${aws_s3_bucket.newrelic_for_cloudwatch_logs_bucket.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "newrelic_firehose_stream_assume_role_for_cloudwatch_logs_filter_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["logs.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}

data "aws_iam_policy_document" "newrelic_firehose_stream_for_cloudwatch_logs_filter_policy_document" {
  statement {
    actions = [
      "firehose:PutRecord",
    ]
    resources = [
      aws_kinesis_firehose_delivery_stream.newrelic_firehose_stream_for_cloudwatch_logs.arn,
    ]
  }
}