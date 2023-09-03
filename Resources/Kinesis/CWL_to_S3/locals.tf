locals {
  create_policies = {
    CWL-To-S3-Kinesis-Policy = data.aws_iam_policy_document.kinesis.json
  }
}
