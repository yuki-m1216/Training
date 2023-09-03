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
      #   "arn:aws:logs:${AWS_REGION}:${ACCOUNT_ID}:log-group:${FIREHOSE_CWL_ERROR_LOG_GROUP_NAME}:log-stream:*"
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
