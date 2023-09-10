data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kinesis" {
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
      "logs:PutLogEvents",
    ]
    resources = [
      module.s3_bucket_for_kinesis.s3_bucket.arn,
      "${module.s3_bucket_for_kinesis.s3_bucket.arn}/*",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:log-group:/aws/kinesisfirehose/CWL-To-S3-Kinesis:log-stream:*"
    ]
  }
}

data "aws_iam_policy_document" "subscription_filter" {
  statement {
    actions = [
      "firehose:PutRecord",
      "firehose:PutRecordBatch",
    ]
    resources = [
      "arn:aws:firehose:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:deliverystream/CWL-To-S3-Kinesis"
    ]
  }
}


/*
aws_kms_aliasで取得するとKinesisのコンソール上カスタマーマネージドCMKを選択したことになるため、
aws_kms_keyで対応
*/
data "aws_kms_key" "s3" {
  key_id = "alias/aws/s3"
}
